require 'socket'

require 'websocket/driver'
require 'aasm'

require 'codeme/common'

require 'codeme/agent/config'
require 'codeme/agent/component'
require 'codeme/agent/request_pool'



module Codeme
  module Agent
    class SystemHandler < Handler
      def resolve(action_code, data = nil)
        puts "action code: #{action_code}, data: #{data}, env: #{@env}"
      end
    end
  end
end




module Codeme
  module Agent
    class Connection < Component
      include AASM

      aasm do
        state :init, initial: true
        state :connecting
        state :auth_pending
        state :ready

        event :connect do
          transitions from: :init, to: :connecting, after: Proc.new { Logger.info "Start connecting" }
        end
        
        event :auth_request do
          transitions from: :connecting, to: :auth_pending, after: Proc.new { Logger.info "Sending authorization request" }
        end
        
        event :auth_success do
          transitions from: :auth_pending, to: :ready, after: Proc.new { Logger.info "Authorization finished" }
        end

        event :reset do
          transitions to: :init, after: Proc.new { Logger.info "Connection state reset" }
        end
      end


      attr_reader :url
      def initialize(master)
        super()
        @master = master
        @url = "#{Config.use_ssl ? "wss" : "ws"}://#{Config.host}:#{Config.port}"
        self.reset
        
        @host = Config.host
        @port = Config.port
        @tag = 0
        
        @request_pool = RequestPool.new
        @request_pool.set_handler(:request_timedout, method(:handle_request_timedout))
        @request_pool.set_handler(:request_meet, method(:handle_request_meet))
        @request_pool.set_handler(:send_request, method(:handle_send_request))
        
        Codeme::Resolver.config do
          handler TYPE_CODE_SYSTEM,  SystemHandler
        end
      end

      def handle_request_timedout(req)
        @master.send_event(EVENT_CONNECTION_NOT_READY, "Connection not ready for #{req.ev_type}:#{req.ev_body}")
      end

      def handle_request_meet(req, res)
        Logger.debug "Got packet: #{res.ev_type}: #{res.ev_body}"
        @master.send_event(EVENT_BEEP, ["ok", "no"].sample)
      end

      def handle_send_request(req)
        if self.ready?
          @driver.binary(Packet.new(req.ev_type, @tag, req.wrap_body).dump)
          true
        else
          false
        end
      end

      # override
      def worker_loop
        loop do
          @request_pool.update
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

      def start_web_driver
        @driver = WebSocket::Driver.client(self)
        @driver.on :open, proc { |e| 
          Logger.info "Server opened"
          self.auth_request
          # Send auth request
          @driver.binary(Packet.new(TYPE_CODE_AUTH | ACTION_CODE_AUTH_TOKEN, 0, [@master.serial_number,"ABC123"].join(",")).dump)
        }
        @driver.on :close, proc { |e| 
          Logger.info "Server closed"
          self.reset
        }
        @driver.on :message, proc { |e|
          pkt = Packet.load(e.data)
          process_packet(pkt) if pkt
        }
        @driver.start
        self.connect
      end

      def register_socket_io
        _monitor = @selector.register(@io, :r)
        _monitor.value = proc do
          msg = @io.recv_nonblock(65535)
          if msg.empty?
            # socket closed
            close_socket_io
            self.reset
          else
            @driver.parse(msg)
          end
        end
      end

      def try_create_socket
        Logger.info "try to re-open socket..."
        TCPSocket.new(@host, @port)
      rescue
        nil
      end

      def close_socket_io
        Logger.info "Socket IO Closed and Deregistered"
        @selector.deregister(@io)
        @io.close
        @io = nil
      end

      def write(string)
        @io.write(string)
      rescue
        Logger.error "Write Error"
        close_socket_io
        self.reset
      end

      def process_packet(pkt)
        if self.auth_pending?
          if pkt.type == TYPE_CODE_AUTH | ACTION_CODE_AUTH_RESULT
            if pkt.body == "0" # true
              @tag = pkt.tag
              Logger.info "Auth Success, connection established, tag = #{@tag}"
              self.auth_success
            else
              Logger.error "Auth Failure"
            end
          else
            Logger.error "Auth error: Not an auth result packet"
          end
        else
          if pkt.tag == @tag
            Resolver.resolve(pkt) 
          end
          # TODO: check packet type
          # if packet is CARD_RESULT
          @request_pool.add_response(Response.new(pkt.type, pkt.body))
        end
      end

      def process_event(ev_type, ev_body)
        case ev_type
        when EVENT_CARD_DATA
          req = Request.new(ev_type, ev_body, ev_body)
          @request_pool.add_request(req)
        end
      end
    end
  end
end

