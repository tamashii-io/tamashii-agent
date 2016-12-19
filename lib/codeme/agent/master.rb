require 'codeme/agent/connection'
require 'codeme/agent/buzzer'
require 'codeme/agent/card_reader'

require 'thread'

module Codeme
  module Agent
    class Master < Component

      attr_reader :serial_number

      def initialize(host, port)
        super()
        @host = host
        @port = port
        @serial_number = get_serial_number
        create_components
      end

      def get_serial_number
        File.open("/proc/cpuinfo") do |f|
          content = f.read
          if content =~ /Serial\s*:\s*(\w+)/
            return $1
          end
        end
        return nil
      end

      def create_components
        @components = {}
        @components[:connection] = create_component(Connection, self, @host, @port) do  |c|
          c.enable_log = true
        end
        @components[:buzzer] = create_component(Buzzer) do  |c|
          c.enable_log = true
        end
        @components[:card_reader] = create_component(CardReader, self) do  |c|
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
          broadcast_event(EVENT_BEEP, "error")
        else
          broadcast_event(ev_type, ev_body)
        end
      end

      # override
      def stop
        super
        @components.each_value do |c|
          c.stop
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
