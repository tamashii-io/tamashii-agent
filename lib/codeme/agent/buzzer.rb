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
          Logger.debug "Beep: #{ev_body}"
          case ev_body
          when "ok"
            PIBuzzer.play_ok
          when "no"
            PIBuzzer.play_no
          when "error"
            PIBuzzer.play_error
          end
        end
      end

      def clean_up
        super
        PIBuzzer.stop

      end
    end
  end
end

