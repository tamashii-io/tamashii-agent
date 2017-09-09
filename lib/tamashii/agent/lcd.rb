require 'concurrent'

require 'tamashii/agent/common'
require 'tamashii/agent/event'
require 'tamashii/agent/adapter/lcd'


module Tamashii
  module Agent
    class LCD < Component

      class LineAnimator
        include Common::Loggable
        attr_reader :text

        def self.line_width=(value)
          @@line_width = value
        end

        def self.handler_print_line=(value)
          @@handler_print_line = value
        end

        def initialize(line)
          @line = line
          @text = ""
          @pos = -1
          @stop_animation = false
        end

        def set_text(text)
          return if text == @text
          stop_animation
          @text = text || ""
          if @text.size > @@line_width
            start_animation
          else
            print_text(@text)
          end
        end

        def animation_show_text
          text = @text[@pos, @@line_width]
          @pos += 1
          @pos = 0 if @pos > @max_pos
          print_text(text)
        end

        def start_animation
          @pos = 0
          @max_pos = @text.size - @@line_width
          @stop_animation = false
          logger.debug "Start animation for line #{@line}: #{@text}"
          @animation_thread = Thread.new { animation_loop }
        end

        def animation_loop
          loop do
            sleep Config.lcd_animation_delay
            animation_show_text
            break if @stop_animation
            sleep Config.lcd_animation_delay if @pos == 0 || @pos == @max_pos
          end
        end

        def stop_animation
          @stop_animation = true
          if @animation_thread
            @animation_thread.join(Config.lcd_animation_delay * 3)
            @animation_thread.exit 
            @animation_thread = nil
          end
        end

        def print_text(text)
          @@handler_print_line&.call(text, @line)
        end
      end

      def initialize(name, master, options = {})
        super
        load_lcd_device
        @device_line_count = @lcd.class::LINE_COUNT
        @device_lock = Mutex.new
        create_line_animators
        set_idle_text("[Tamashii]\nIdle...")
        logger.debug "Using LCD instance: #{@lcd.class}"
        print_message("Initializing\nPlease wait...")
        schedule_to_print_idle
      end

      def create_line_animators
        LineAnimator.line_width = @lcd.class::WIDTH
        LineAnimator.handler_print_line = method(:print_line)
        @line_animators = [] 
        @device_line_count.times {|i| @line_animators << LineAnimator.new(i)}
      end

      def load_lcd_device
        @lcd = Adapter::LCD.object
      rescue => e
        logger.error "Unable to load LCD instance: #{Adapter::LCD.current_class}"
        logger.error "Use #{Adapter::LCD.fake_class} instead"
        @lcd = Adapter::LCD.fake_class.new
      end

      def print_message(message)
        lines = message.lines.map{|l| l.delete("\n")} 
        @device_line_count.times do |line_count|
          @line_animators[line_count].set_text(lines[line_count])
        end
      end

      def print_line(*args)
        @device_lock.synchronize do
          @lcd.print_line(*args)
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
        print_message(@idle_text)
      end

      def process_event(event)
        case event.type
        when Event::LCD_MESSAGE
          logger.debug "Show message: #{event.body}"
          @back_to_idle_task&.cancel
          print_message(event.body)
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
        print_message("")
      end

      def clean_up
        clear_screen
        super
      end
    end
  end
end

