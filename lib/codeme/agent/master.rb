require 'codeme/agent/connection'

require 'thread'

module Codeme
  module Agent
    class Master < Component
      def initialize
        super
        @c = Connection.new(self, "127.0.0.1", 4180)
        @c.run

        @selector = NIO::Selector.new
        @selector.register(@pipe_r, :r)

        @c.enable_log = true
      end

      def run
        loop do
          ready = @selector.select
          if ready
            # read the event
            receive_event
          end
        end
      end

      def broadcast_event(ev_type, ev_body)
        @c.send_event(ev_type, ev_body)
      end
    end
  end
end
