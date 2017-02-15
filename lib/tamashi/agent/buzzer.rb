require 'tamashi/agent/component'
require 'tamashi/agent/adapter/buzzer'

module Tamashi
  module Agent
    class Buzzer < Component
      def initialize
        super
        @buzzer = Adapter::Buzzer.object
        logger.debug "Using buzzer instance: #{@buzzer.class}"
      end

      def process_event(ev_type, ev_body)
        case ev_type
        when EVENT_BEEP
          logger.debug "Beep: #{ev_body}"
          case ev_body
          when "ok"
            @buzzer.play_ok
          when "no"
            @buzzer.play_no
          when "error"
            @buzzer.play_error
          end
        end
      end

      def clean_up
        super
        @buzzer.stop
      end
    end
  end
end

