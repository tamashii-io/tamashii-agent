require 'tamashii/agent/component'
require 'tamashii/agent/event'

module Tamashii
  module Agent
    class Buzzer < Component
      def initialize(name, master, options = {})
        super
        @buzzer = initialize_device
      end

      def default_device_name
        'Dummy'
      end

      def get_device_class_name(device_name)
        "Buzzer::#{device_name}"
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
        @buzzer.shutdown
      end
    end
  end
end

