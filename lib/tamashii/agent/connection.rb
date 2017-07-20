require 'socket'
require 'websocket/driver'
require 'aasm'
require 'openssl'
require 'json'
require 'concurrent'

require 'tamashii/common'

require 'tamashii/agent/config'
require 'tamashii/agent/component'

require 'tamashii/agent/handler'

module Tamashii
  module Agent
    class Connection < Component

      class RequestTimeoutError < RuntimeError; end

      class RequestObserver
        include Common::Loggable
        def initialize(connection, id, ev_type, ev_body, future)
          @connection = connection
          @id = id
          @ev_type = ev_type
          @ev_body = ev_body
          @future = future
        end

        def update(time, ev_data, reason)
          if @future.fulfilled?
            res_ev_type = ev_data[:ev_type]
            res_ev_body = ev_data[:ev_body]
            case res_ev_type
            when Type::RFID_RESPONSE_JSON
              logger.debug "Handled: #{res_ev_type}: #{res_ev_body}"
              @connection.handle_card_result(JSON.parse(res_ev_body))
            else
              logger.warn "Unhandled packet result: #{res_ev_type}: #{res_ev_body}"
            end
          else
            logger.error "#{@id} Failed with #{reason}"
            @connection.on_request_timeout(@ev_type, @ev_body)
          end
        end
      end

      include AASM

      TIMEOUT = 3

      aasm do
        state :init, initial: true
        state :connecting
        state :auth_pending
        state :ready

        event :connect do
          transitions from: :init, to: :connecting, after: Proc.new { logger.info "Start connecting" }
        end

        event :auth_request do
          transitions from: :connecting, to: :auth_pending, after: Proc.new { logger.info "Sending authentication request" }
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

      def initialize(master, host, port)
        super()
        @master = master
        @url = "#{Config.use_ssl ? "wss" : "ws"}://#{host}:#{port}/#{Config.entry_point}"
        self.reset

        @host = host
        @port = port
        @tag = 0

        @future_ivar_pool = Concurrent::Map.new

        setup_resolver
      end

      def setup_resolver
        env_data = {connection: self}
        Resolver.config do
          [Type::REBOOT, Type::POWEROFF, Type::RESTART, Type::UPDATE].each do |type|
            handle type,  Handler::System, env_data
          end
          handle Type::BUZZER_SOUND,  Handler::Buzzer, env_data
          handle Type::RFID_RESPONSE_JSON,  Handler::RemoteResponse, env_data
        end
      end

      def on_request_timeout(ev_type, ev_body)
        @master.send_event(EVENT_CONNECTION_NOT_READY, "Connection not ready for #{ev_type}:#{ev_body}")
      end

      def handle_card_result(result)
        if result["auth"]
          @master.send_event(EVENT_BEEP, "ok")
        else
          @master.send_event(EVENT_BEEP, "no")
        end
      end

      def try_send_request(ev_type, ev_body)
        if self.ready?
          @driver.binary(Packet.new(ev_type, @tag, ev_body).dump)
          true
        else
          false
        end
      end

      # override
      def worker_loop
        loop do
          ready = @selector.select(1)
          ready.each { |m| m.value.call } if ready
          if @io.nil?
            @io = try_create_socket
            if @io
              # socket io opened
              register_socket_io
              # start ws
              start_web_driver
            end
          end
        end
      end

      def send_auth_request
        # TODO: other types of auth
        @driver.binary(Packet.new(Type::AUTH_TOKEN, 0, [Type::CLIENT[:agent], @master.serial_number,Config.token].join(",")).dump)
      end

      def start_web_driver
        # TODO: Improve below code
        @driver = WebSocket::Driver.client(self)
        @driver.on :open, proc { |e|
          logger.info "Server opened"
          self.auth_request
          send_auth_request
        }
        @driver.on :close, proc { |e|
          logger.info "Server closed"
          close_socket_io
          self.reset
        }
        @driver.on :message, proc { |e|
          pkt = Packet.load(e.data)
          process_packet(pkt) if pkt
        }
        @driver.on :error, proc { |e|
          logger.error("#{e.message}")
        }
        @driver.start
        self.connect
      end

      def register_socket_io
        _monitor = @selector.register(@io, :r)
        _monitor.value = proc do
          begin
            msg = @io.read_nonblock(4096, exception: false)
            next if msg == :wait_readable
            if msg.nil?
              # socket closed
              logger.info "No message received from server. Connection reset"
              close_socket_io
              self.reset
              sleep 1
            else
              @driver.parse(msg)
            end
          rescue => e
            logger.error "#{e.message}"
            logger.debug "Backtrace:"
            e.backtrace.each {|msg| logger.debug msg}
          end
        end
      end

      def try_create_socket
        logger.info "try to open socket..."
        if Config.use_ssl
          OpenSSL::SSL::SSLSocket.new(TCPSocket.new(@host, @port)).connect
        else
          TCPSocket.new(@host, @port)
        end
      rescue
        nil
      end

      def close_socket_io
        logger.info "Socket IO Closed and Deregistered"
        @selector.deregister(@io)
        @io.close
        @io = nil
      end

      def write(string)
        @io.write(string)
      rescue
        logger.error "Write Error"
        close_socket_io
        self.reset
      end

      def process_packet(pkt)
        if self.auth_pending?
          if pkt.type == Type::AUTH_RESPONSE
            if pkt.body == Packet::STRING_TRUE
              @tag = pkt.tag
              self.auth_success
            else
              logger.error "Authentication failed. Delay for 3 seconds"
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

      def process_event(ev_type, ev_body)
        case ev_type
        when EVENT_CARD_DATA
          id = ev_body
          wrapped_body = {
            id: ev_body,
            ev_body: ev_body
          }.to_json
          new_remote_request(id, Type::RFID_NUMBER, wrapped_body)
        end
      end

      def create_request_scheduler_task(id, ev_type, ev_body)
        start_time = Time.now
        schedule_runner = proc do |id, times|
          logger.debug "Schedule send attemp #{id} : #{times + 1} time(s)"
          if try_send_request(ev_type, ev_body)
            # Request sent, do nothing
            logger.debug "Request sent for id = #{id}"
          else
            if Time.now - start_time < TIMEOUT
              # Re-schedule self
              logger.warn "Reschedule #{id} after 1 sec"
              Concurrent::ScheduledTask.execute(1, args: [id, times + 1], &schedule_runner)
            else
              # This job is expired. Do nothing
              logger.warn "Abort scheduling #{id}"
            end
          end
        end
        Concurrent::ScheduledTask.execute(0, args: [id, 0], &schedule_runner)
      end

      def create_request_async(id, ev_type, ev_body)
        req = Concurrent::Future.new do
          # Create IVar for store result
          ivar = Concurrent::IVar.new
          @future_ivar_pool[id] = ivar
          # Schedule to get the result
          create_request_scheduler_task(id, ev_type, ev_body)
          # Wait for result
          if result = ivar.value(TIMEOUT)
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

      def clean_up
        super
        if @io
          @driver.close
          close_socket_io
        end
      rescue => e
        logger.warn "Error occured when clean up: #{e.to_s}"
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

