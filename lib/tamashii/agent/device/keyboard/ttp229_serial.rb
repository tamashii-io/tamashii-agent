require 'pi_piper'
require 'tamashii/agent/device/keyboard/base'

module Tamashii
  module Agent
    module Device
      module Keyboard
        class TTP229Serial < Base

          HALF_BIT_TIME=0.001

          def initialize_hardware
            @scl_pin = PiPiper::Pin.new(pin: fetch_option(:scl_pin, default_scl_pin), direction: :out)
            @sdo_pin = PiPiper::Pin.new(pin: fetch_option(:sdo_pin, default_sdo_pin), direction: :in)
            @scl_pin.on
            sleep(HALF_BIT_TIME)
          end

          def polling_interval
            10*HALF_BIT_TIME
          end

          def default_number_of_keys
            8
          end

          def default_scl_pin
            17
          end

          def default_sdo_pin
            4
          end
          
          def finalize_hardware
            unexport_pin(@scl_pin.pin)
            unexport_pin(@sdo_pin.pin)
          end

          def read_key
            current_key = nil
            @number_of_keys.times do |key|
              @scl_pin.off
              sleep(HALF_BIT_TIME)
              @sdo_pin.read
              if @sdo_pin.off?
                current_key = key
                mark_key_down(key)
              else
                mark_key_up(key)
              end
              @scl_pin.on
              sleep(HALF_BIT_TIME)
            end
            current_key
          end
        end
      end
    end
  end
end
