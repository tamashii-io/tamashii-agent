require 'concurrent'

require 'tamashii/agent/common'
require 'tamashii/agent/event'
require 'tamashii/agent/adapter/lcd'



Thread.abort_on_exception = true


module Tamashii
  module Agent
    class LCD < Component
      def initialize
        super
        @lcd = Adapter::LCD.object
        @device_lock = Mutex.new
        @idle_message = "[5xruby]\nIdle..."
        logger.debug "Using LCD instance: #{@lcd.class}"
        @lcd.print_message("Initializing\nPlease wait...")
        schedule_to_print_idle
      end

      def schedule_to_print_idle(delay = 2)
        @back_to_idle_task = Concurrent::ScheduledTask.execute(delay) do
          @device_lock.synchronize do
            @lcd.print_message(@idle_message)
          end
        end
      end

      def process_event(event)
        case event.type
        when Event::BEEP
          logger.debug "Beep: #{event.body}"
          @back_to_idle_task&.cancel
          @device_lock.synchronize do
            @lcd.print_message(event.body)
            schedule_to_print_idle
          end
        end
      end

      def clear_screen
        @device_lock.synchronize do
          @lcd.print_message("")
        end
      end

      def clean_up
        clear_screen
        super
      end
    end
  end
end




