require 'tamashii/agent/component'
require 'tamashii/agent/event'

module Tamashii
  module Agent
    class KeyboardLogger < Component
      def initialize(name, master, options = {})
        options[:watch] = true # Force enable watch mode
        super
        @kb = initialize_device
        @kb.on_key_down do |key|
          logger.debug "Key down: #{key+1}"
          @master.send_event(Event.new(Event::LCD_MESSAGE, "Key pressed: #{key+1} "))
        end
      end

      def default_device_name
        'Dummy'
      end

      def get_device_class_name(device_name)
        "Keyboard::#{device_name}"
      end

      # override
      def process_event(event)
        # silent is gold
      end

      def clean_up
        super
        @kb.shutdown
      end
    end
  end
end

