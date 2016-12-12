require 'codeme/agent/component'
require 'codeme/agent/pi_buzzer'

module Codeme
  module Agent
    class Buzzer < Component
      def initialize
        super
        PIBuzzer.setup
      end

      def process_event(ev_type, ev_body)
        case ev_type
        when EVENT_BEEP
          log "Beep: #{ev_body}"
          PIBuzzer.play_ok
        end
      end

      def clean_up
        super
        PIBuzzer.stop

      end
    end
  end
end

