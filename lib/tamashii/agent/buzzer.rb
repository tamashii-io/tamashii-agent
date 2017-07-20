require 'tamashii/agent/component'
require 'tamashii/agent/event'
require 'tamashii/agent/adapter/buzzer'

module Tamashii
  module Agent
    class Buzzer < Component
      def initialize
        super
        @buzzer = Adapter::Buzzer.object
        logger.debug "Using buzzer instance: #{@buzzer.class}"
      end

      def process_event(event)
        case event.type
        when Event::BEEP
          logger.debug "Beep: #{event.body}"
          case event.body
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

