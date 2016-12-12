require 'codeme/agent/component'

module Codeme
  module Agent
    class Buzzer < Component
      def initialize
        super
      end

      def process_event(ev_type, ev_body)
        case ev_type
        when EVENT_BEEP
          log "Beep: #{ev_body}"
        end
      end
    end
  end
end

