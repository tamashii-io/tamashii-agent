require 'pi_piper'
require 'tamashii/agent/device/keyboard/base'

module Tamashii
  module Agent
    module Device
      module Keyboard
        class ButtonMatrix4x4 < Base

          def initialize_hardware
            @row_pins = fetch_option(:row_pins, default_row_pins).map do |pin_number|
              PiPiper::Pin.new(pin: pin_number, direction: :out).tap {|pin| pin.on} 
            end
            @col_pins = fetch_option(:col_pins, default_col_pins).map do |pin_number|
              PiPiper::Pin.new(pin: pin_number, direction: :in, pull: :up)
            end
          end

          def number_of_keys
            16
          end

          def polling_interval
            0.01
          end

          def default_row_pins
            [21, 20, 16, 12]
          end

          def default_col_pins
            [26, 19, 13, 6]
          end
          
          def finalize_hardware
            (@row_pins + @col_pins).each do |pin|
              unexport_pin(pin.pin)
            end
          end

          def read_key
            current_key = nil
            @row_pins.each_with_index do |row_pin, row_index|
              row_pin.off
              @col_pins.each_with_index do |col_pin, col_index|
                col_pin.read
                key = row_index * 4 + col_index
                if col_pin.off?
                  current_key = key
                  mark_key_down(key)
                else
                  mark_key_up(key)
                end
              end
              row_pin.on
              sleep 0.001
            end
            current_key
          end
        end
      end
    end
  end
end
