require 'socket'

require 'websocket/driver'
require 'codeme/common'

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
      attr_reader :url
      def initialize(master, host, port)
        super()
        @master = master
        @url = "ws://#{host}:#{port}"
        @ready = false
        @host = host
        @port = port
        @tag = rand(60000) # TODO: get tag first!
        
        @request_pool = RequestPool.new
        @request_pool.set_handler(:request_timedout, method(:handle_request_timedout))
        @request_pool.set_handler(:request_meet, method(:handle_request_meet))
        @request_pool.set_handler(:send_request, method(:handle_send_request))
        
        Codeme::Resolver.config do
          handler TYPE_SYSTEM,  SystemHandler
        end
      end

      def handle_request_timedout(req)
        @master.send_event(EVENT_CONNECTION_NOT_READY, "Connection not ready for #{req.ev_type}:#{req.ev_body}")
      end

      def handle_request_meet(req, res)
        log "Got packet: #{res.ev_type}: #{res.ev_body}"
        @master.send_event(EVENT_BEEP, ["ok", "no"].sample)
      end

      def handle_send_request(req)
        if @ready
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
          log "Server opened"
          @ready = true
        }
        @driver.on :close, proc { |e| 
          log "Server closed"
          @ready = false
        }
        @driver.on :message, proc { |e|
          pkt = Packet.load(e.data)
          process_packet(pkt)
        }
        @driver.start
      end

      def register_socket_io
        _monitor = @selector.register(@io, :r)
        _monitor.value = proc do
          msg = @io.recv_nonblock(65535)
          if msg.empty?
            # socket closed
            close_socket_io
            @ready = false
          else
            @driver.parse(msg)
          end
        end
      end

      def try_create_socket
        log "try to re-open socket..."
        TCPSocket.new(@host, @port)
      rescue
        nil
      end

      def close_socket_io
        log "Socket IO Closed and Deregistered"
        @selector.deregister(@io)
        @io.close
        @io = nil
      end

      def write(string)
        @io.write(string)
      rescue
        log "Write Error"
        close_socket_io
        @ready = false
      end

      def process_packet(pkt)
        if pkt.tag == @tag
          Resolver.resolve(pkt) 
        end
        # TODO: check packet type
        # if packet is CARD_RESULT
        @request_pool.add_response(Response.new(pkt.type, pkt.body))
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

