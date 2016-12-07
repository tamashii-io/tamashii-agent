$LOAD_PATH << "#{File.dirname(__FILE__)}/codeme-common/lib"
$LOAD_PATH << "#{File.dirname(__FILE__)}/lib"

require 'component'
require 'packet'
require 'websocket/driver'
require 'socket'
require 'nio'

module Codeme
  class Connection < Component
    attr_reader :url
    def initialize(master, host, port)
      super()
      @master = master
      @url = "ws://#{host}:#{port}"
      @ready = false
      @host = host
      @port = port
    end

    def run
      @thr = Thread.start { worker_loop }
    end

    def stop
      @thr.exit if @thr
      @thr = nil
    end

    def create_socket
      until @io
        @io = TCPSocket.new(@host, @port) rescue nil
        unless @io
          log "TCP Connection Error, retrying..."
          sleep 1
        end
      end
    end

    def worker_loop
      # Socket
      create_socket
      
      @selector = NIO::Selector.new
      # Socket IO
      register_socket_io
      
      # Event IO
      register_event_io
      
      # WS driver
      start_web_driver
      
      loop do
        ready = @selector.select(1)
        ready.each { |m| m.value.call } if ready
        if @io.nil?
          @io = try_create_socket
          if @io
            # io re-opened
            register_socket_io
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

    def register_event_io
      _monitor = @selector.register(@pipe_r, :r)
      _monitor.value = method(:receive_event)
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
      @master.send_event(pkt.type + 1, "Got packet: #{pkt.type}: #{pkt.body}")
    end
    
    def process_event(ev_type, ev_body)
      if @ready
        @driver.text(Packet.new(ev_type, ev_body).dump)
      else
        @master.send_event(EVENT_CONNECTION_NOT_READY, "Connection not ready")
      end
    end
  end
end

