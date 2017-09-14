require 'pi_piper'
require 'tamashii/agent/device/buzzer/base'

module Tamashii
  module Agent
    module Device
      module Buzzer
        class PwmBuzzer < Base

          SHORT_PLAY_TIME = 0.2
          LONG_PLAY_TIME = 0.5
          REPEAT_INTERVAL = 0.1
          LOW_FREQ = 0.7

          def initialize(*args)
            super
            setup_pwm
          end

          def shutdown
            stop
          end

          def play_ok
            play_repeat_short(1)
          end

          def play_no
            play_repeat_short(3)
          end

          def play_error
            play_repeat_long(3)
          end

          def default_pin
            18
          end

          private

          def stop
            @pwm.off
          end

          def setup_pwm
            pin = fetch_option(:pin, default_pin)
            @pwm = PiPiper::Pwm.new pin: pin #, mode: :markspace
            @pwm.off
            @pwm.value = 1.0
          end

          def play(value = 1.0)
            @pwm.value = value
            @pwm.on
          end

          def play_short(value = 1.0)
            play_time(SHORT_PLAY_TIME,value)
          end

          def play_long(value = 1.0)
            play_time(LONG_PLAY_TIME,value)
          end

          def play_time(time, value = 1.0)
            play(value)
            sleep time
            stop
          end

          def play_repeat_short(repeat, repeat_interval = REPEAT_INTERVAL)
            repeat.times do
              play_short
              sleep repeat_interval
            end
          end

          def play_repeat_long(repeat, repeat_interval = REPEAT_INTERVAL)
            repeat.times do
              play_long
              sleep repeat_interval
            end
          end
        end
      end
    end
  end
end
