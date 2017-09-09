require 'aasm'
require 'json'
require 'concurrent'

require 'tamashii/common'

require 'tamashii/agent/config'
require 'tamashii/agent/event'
require 'tamashii/agent/component'

require 'tamashii/agent/handler'

require 'tamashii/client'

module Tamashii
  module Agent
    class Networking < Component

      autoload :RequestObserver, 'tamashii/agent/networking/request_observer'

      class RequestTimeoutError < RuntimeError; end

      include AASM

      aasm do
        state :init, initial: true
        state :auth_pending
        state :ready

        event :auth_request do
          transitions from: :init, to: :auth_pending, after: Proc.new { logger.info "Sending authentication request" }
        end

        event :auth_success do
          transitions from: :auth_pending, to: :ready, after: Proc.new { logger.info "Authentication finished. Tag = #{@tag}" }
        end

        event :reset do
          transitions to: :init, after: Proc.new { logger.info "Connection state reset" }
        end
      end

      attr_reader :url
      attr_reader :master

      def initialize(name, master, options = {})
        super

        self.reset
        @client = Tamashii::Client::Base.new

        @tag = 0

        @future_ivar_pool = Concurrent::Map.new

        @last_error_report_time = Time.now
        setup_callbacks
        setup_resolver
      end

      def setup_resolver
        env_data = {networking: self, master: @master}
        Resolver.config do
          [Type::REBOOT, Type::POWEROFF, Type::RESTART, Type::UPDATE].each do |type|
            handle type,  Handler::System, env_data
          end
          [Type::LCD_MESSAGE, Type::LCD_SET_IDLE_TEXT].each do |type|
            handle type,  Handler::LCD, env_data
          end
          handle Type::BUZZER_SOUND,  Handler::Buzzer, env_data
          handle Type::RFID_RESPONSE_JSON,  Handler::RemoteResponse, env_data
        end
      end

      def on_request_timeout(ev_type, ev_body)
        @master.send_event(Event.new(Event::CONNECTION_NOT_READY, "Connection not ready for #{ev_type}:#{ev_body}"))
      end

      def handle_card_result(result)
        if result["auth"]
          @master.send_event(Event.new(Event::BEEP, "ok"))
        else
          @master.send_event(Event.new(Event::BEEP, "no"))
        end
        if result["message"]
          @master.send_event(Event.new(Event::LCD_MESSAGE, result["message"]))
        end
      end

      def try_send_request(ev_type, ev_body)
        if self.ready?
          @client.transmit(Packet.new(ev_type, @tag, ev_body).dump)
          true
        else
          false
        end
      end

      def stop_threads
        super
        @client.close
      end

      def send_auth_request
        # TODO: other types of auth
        if @client.transmit(Packet.new(Type::AUTH_TOKEN, 0, [Type::CLIENT[:agent], @master.serial_number,Config.token].join(",")).dump)
          logger.debug "Auth sent!"	
        else
          logger.error "Cannot sent auth request!"
	end
      end

      def setup_callbacks
        @client.on :open, proc {
          logger.info "Server opened"
          self.auth_request
          send_auth_request
        }
        @client.on :close, proc {
          # Note: this only called when normally receive the WS close message
          logger.info "Server closed normally"
        }
        @client.on :socket_closed, proc {
          # Note: called when low-level IO is closed
          logger.info "Server socket closed"
          self.reset
        }
        @client.on :message, proc { |data| 
          pkt = Packet.load(data)
          process_packet(pkt) if pkt
        }
        @client.on :error, proc { |e|
          logger.error("#{e.message}")
        }
      end


      def process_packet(pkt)
        if self.auth_pending?
          if pkt.type == Type::AUTH_RESPONSE
            if pkt.body == Packet::STRING_TRUE
              @tag = pkt.tag
              self.auth_success
            else
              logger.error "Authentication failed. Delay for 3 seconds"
              @master.send_event(Event.new(Event::LCD_MESSAGE, "Fatal Error\nAuth Failed"))
              sleep 3
            end
          else
            logger.error "Authentication error: Not an authentication result packet"
          end
        else
          if pkt.tag == @tag || pkt.tag == 0
            Resolver.resolve(pkt)
          else
            logger.debug "Tag mismatch packet: tag: #{pkt.tag}, type: #{pkt.type}"
          end
        end
      end

      # override
      def process_event(event)
        case event.type
        when Event::CARD_DATA
          if self.ready?
            id = event.body
            wrapped_body = {
              id: id,
              ev_body: event.body
            }.to_json
            new_remote_request(id, Type::RFID_NUMBER, wrapped_body)
          else
            @master.send_event(Event.new(Event::CONNECTION_NOT_READY, "Connection not ready for #{event.type}:#{event.body}"))
          end
        end
      end

      def schedule_task_runner(id, ev_type, ev_body, start_time, times)
        logger.debug "Schedule send attemp #{id} : #{times + 1} time(s)"
        if try_send_request(ev_type, ev_body)
          # Request sent, do nothing
          logger.debug "Request sent for id = #{id}"
        else
          if Time.now - start_time < Config.connection_timeout
            # Re-schedule self
            logger.warn "Reschedule #{id} after 1 sec"
            schedule_next_task(1, id,  ev_type, ev_body, start_time, times + 1)
          else
            # This job is expired. Do nothing
            logger.warn "Abort scheduling #{id}"
          end
        end
      end

      def schedule_next_task(interval, id, ev_type, ev_body, start_time, times)
        Concurrent::ScheduledTask.execute(interval, args: [id, ev_type, ev_body, start_time, times], &method(:schedule_task_runner))
      end

      def create_request_scheduler_task(id, ev_type, ev_body)
        schedule_next_task(0, id, ev_type, ev_body, Time.now, 0)
      end

      def create_request_async(id, ev_type, ev_body)
        req = Concurrent::Future.new do
          # Create IVar for store result
          ivar = Concurrent::IVar.new
          @future_ivar_pool[id] = ivar
          # Schedule to get the result
          create_request_scheduler_task(id, ev_type, ev_body)
          # Wait for result
          if result = ivar.value(Config.connection_timeout)
            # IVar is already removed from pool
            result
          else
            # Manually remove IVar
            # Any fulfill at this point is useless
            logger.error "Timeout when getting IVar for #{id}"
            @future_ivar_pool.delete(id)
            raise RequestTimeoutError, "Request Timeout"
          end
        end
        req.add_observer(RequestObserver.new(self, id, ev_type, ev_body, req))
        req.execute
        req
      end

      def new_remote_request(id, ev_type, ev_body)
        # enqueue if not exists
        if !@future_ivar_pool[id]
          create_request_async(id, ev_type, ev_body)
          logger.debug "Request created: #{id}"
        else
          logger.warn "Duplicated id: #{id}, ignored"
        end
      end

      # When data is back 
      def handle_remote_response(ev_type, wrapped_ev_body)
        logger.debug "Remote packet back: #{ev_type} #{wrapped_ev_body}"
        result = JSON.parse(wrapped_ev_body)
        id = result["id"]
        ev_body = result["ev_body"]
        # fetch ivar and delete it
        if ivar = @future_ivar_pool.delete(id)
          ivar.set(ev_type: ev_type, ev_body: ev_body)
        else
          logger.warn "IVar #{id} not in pool"
        end
      end
    end
  end
end

