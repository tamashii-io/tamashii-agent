require 'concurrent'

require 'tamashii/agent/common'
require 'tamashii/agent/event'
require 'tamashii/agent/adapter/lcd'


Thread.abort_on_exception = true
module Tamashii
  module Agent
    class LCD < Component
      def initialize(master)
        super
        load_lcd_device
        @device_lock = Mutex.new
        set_idle_text("[Tamashii]\nIdle...")
        logger.debug "Using LCD instance: #{@lcd.class}"
        print_message_with_lock("Initializing\nPlease wait...")
        schedule_to_print_idle
      end

      def load_lcd_device
        @lcd = Adapter::LCD.object
      rescue => e
        logger.error "Unable to load LCD instance: #{Adapter::LCD.current_class}"
        logger.error "Use #{Adapter::LCD.fake_class} instead"
        @lcd = Adapter::LCD.fake_class.new
      end

      def print_message_with_lock(*args)
        @device_lock.synchronize do
          @lcd.print_message(*args)
        end
      end

      def set_idle_text(text)
        @idle_text_raw = text
        @auto_update_interval = 0
        # Time hint
        if @idle_text_raw.include?(Tamashii::AgentHint::TIME)
          @has_time_hint = true
          @auto_update_interval = [@auto_update_interval, 30].max
        else
          @has_time_hint = false
        end
        # clear auto update timer
        @idle_text_timer_task.shutdown if @idle_text_timer_task
        if @auto_update_interval > 0
          setup_idle_text_auto_update
        else
          # one-time setup
          compute_idle_text
        end
      end

      def setup_idle_text_auto_update
        @idle_text_timer_task = Concurrent::TimerTask.new(run_now: true) do 
          compute_idle_text
          print_idle
        end
        @idle_text_timer_task.execution_interval = @auto_update_interval
        @idle_text_timer_task.timeout_interval = @auto_update_interval
        @idle_text_timer_task.execute
      end

      def compute_idle_text
        result = @idle_text_raw.clone
        if @has_time_hint
          result.gsub!(Tamashii::AgentHint::TIME, Time.now.localtime(Config.localtime).strftime("%m/%d(%a) %H:%M"))
        end
        @idle_text = result
        logger.debug "Idle text updated to #{@idle_text}"
      end

      def schedule_to_print_idle(delay = 5)
        @back_to_idle_task = Concurrent::ScheduledTask.execute(delay, &method(:print_idle))
      end

      def print_idle
        print_message_with_lock(@idle_text)
      end

      def process_event(event)
        case event.type
        when Event::LCD_MESSAGE
          logger.debug "Show message: #{event.body}"
          @back_to_idle_task&.cancel
          print_message_with_lock(event.body)
          @device_lock.synchronize do
            schedule_to_print_idle
          end
        when Event::LCD_SET_IDLE_TEXT
          logger.debug "Idle text set to #{event.body}"
          set_idle_text(event.body)
          print_idle
        end
      end

      def clear_screen
        print_message_with_lock("")
      end

      def clean_up
        clear_screen
        super
      end
    end
  end
end




