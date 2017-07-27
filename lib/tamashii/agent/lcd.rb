require 'concurrent'

require 'tamashii/agent/common'
require 'tamashii/agent/event'
require 'tamashii/agent/adapter/lcd'



module Tamashii
  module Agent
    class LCD < Component
      def initialize
        super
        load_lcd_device
        @device_lock = Mutex.new
        @idle_message = "[Tamashii]\nIdle..."
        logger.debug "Using LCD instance: #{@lcd.class}"
        @lcd.print_message("Initializing\nPlease wait...")
        schedule_to_print_idle
      end

      def load_lcd_device
        @lcd = Adapter::LCD.object
      rescue => e
        logger.error "Unable to load LCD instance: #{Adapter::LCD.current_class}"
        logger.error "Use #{Adapter::LCD.fake_class} instead"
        @lcd = Adapter::LCD.fake_class.new
      end

      def schedule_to_print_idle(delay = 5)
        @back_to_idle_task = Concurrent::ScheduledTask.execute(delay) do
          @device_lock.synchronize do
            @lcd.print_message(@idle_message)
          end
        end
      end

      def process_event(event)
        case event.type
        when Event::LCD_MESSAGE
          logger.debug "Show message: #{event.body}"
          @back_to_idle_task&.cancel
          @device_lock.synchronize do
            @lcd.print_message(event.body)
            schedule_to_print_idle
          end
        when Event::LCD_SET_IDLE_TEXT
          logger.debug "Idle text set to #{event.body}"
          @idle_message = event.body
          @device_lock.synchronize do
            @lcd.print_message(event.body)
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




