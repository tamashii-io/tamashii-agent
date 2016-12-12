module Codeme
  module Agent
    class Component

      EVENT_BEEP = 1
      EVENT_SYSTEM_COMMAND = 2
      EVENT_AUTH_RESULT = 3
      EVENT_CARD_DATA = 4
      EVENT_CONNECTION_NOT_READY = 255


      attr_accessor :enable_log

      def initialize
        @enable_log = true
        @pipe_r, @pipe_w = IO.pipe
      end

      def send_event(type, body)
        str = [type, body.size].pack("Cn") + body
        @pipe_w.write(str)
      end

      def receive_event
        ev_type, ev_size = @pipe_r.read(3).unpack("Cn")
        ev_body = @pipe_r.read(ev_size)
        process_event(ev_type, ev_body)
      end

      def process_event(ev_type, ev_body)
        log "Got event: #{ev_type}, #{ev_body}"
      end

      def log(msg)
        puts "[#{self.class}] #{msg}" if @enable_log
      end
    end
  end
end
