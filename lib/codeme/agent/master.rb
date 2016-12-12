require 'codeme/agent/connection'
require 'codeme/agent/buzzer'

require 'thread'

module Codeme
  module Agent
    class Master < Component

      def initialize
        super
        create_components
      end

      def create_components
        @components = {}
        @components[:connection] = create_component(Connection, self, "127.0.0.1", 4180) do  |c|
          c.enable_log = true
        end
        @components[:buzzer] = create_component(Buzzer) do  |c|
          c.enable_log = true
        end
      end

      def create_component(class_name, *args)
        c = class_name.new(*args)
        yield c
        c.run
        c
      end

      # override
      def process_event(ev_type, ev_body)
        super
        case ev_type
        when EVENT_SYSTEM_COMMAND
        when EVENT_CONNECTION_NOT_READY
          broadcast_event(EVENT_BEEP, "Not Ready")
        else
          broadcast_event(ev_type, ev_body)
        end
      end


      def broadcast_event(ev_type, ev_body)
        @components.each_value do |c|
          c.send_event(ev_type, ev_body)
        end
      end
    end
  end
end
