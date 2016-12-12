require 'pi_piper'
module Codeme
  module Agent
    module PIBuzzer
      SHORT_PLAY_TIME = 0.2
      LONG_PLAY_TIME = 0.5
      REPEAT_INTERVAL = 0.1
      LOW_FREQ = 0.7

      module_function
      def self.setup
        @init = true
        @pwm = PiPiper::Pwm.new pin: 18 #, mode: :markspace
        @pwm.off
        @pwm.value = 1.0
      end

      def self.pwm
        @pwm
      end

      def self.play(value = 1.0)
        return if !check_init
        @pwm.value = value
        @pwm.on
      end

      def self.stop
        return if !check_init
        @pwm.off
      end

      def self.check_init
        if !@init
          puts "Need setup first!"
          return false
        end
        return true
      end

      def self.play_short(value = 1.0)
        play_time(SHORT_PLAY_TIME,value)
      end

      def self.play_long(value = 1.0)
        play_time(LONG_PLAY_TIME,value)
      end

      def self.play_time(time, value = 1.0)
        return if !check_init
        play(value)
        sleep time
        stop
      end

      def self.play_repeat_short(repeat, repeat_interval = REPEAT_INTERVAL)
        repeat.times do
          play_short
          sleep repeat_interval
        end
      end

      def self.play_repeat_long(repeat, repeat_interval = REPEAT_INTERVAL)
        repeat.times do
          play_long
          sleep repeat_interval
        end
      end

      def self.play_ok
        play_repeat_short(1)
      end

      def self.play_no
        play_repeat_short(3)
      end

      def self.play_error
        play_repeat_long(3)
      end
    end
  end
end
