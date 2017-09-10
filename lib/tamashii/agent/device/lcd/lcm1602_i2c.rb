require 'i2c'
require 'tamashii/agent/device/lcd/base'

module Tamashii
  module Agent
    module Device
      module Lcd
        class Lcm1602I2c < Base
          WIDTH = 16
          LINE_COUNT = 2

          OP_CHR = 1
          OP_CMD = 0

          LINES  = [
            0x80,
            0xC0
          ].freeze

          BACKLIGHT_ON = 0x08
          BACKLIGHT_OFF = 0x00

          ENABLE = 0b00000100

          PULSE = 0.0005
          DELAY = 0.0005

          attr_accessor :backlight

          def width
            16
          end

          def line_count
            2
          end

          def initialize(*args)
            super
            initialize_lcd
          end

          def default_path
            '/dev/i2c-1'
          end

          def default_address
            0x27
          end

          def print_line(message, line)
            write_line(message, LINES[line])
          end

          def shutdown
            print_message("")
          end

          private

          def fetch_address
            if @options.has_key?(:address)
              address = @options[:address]
            else
              address = default_address
              logger.warn "No address specified. Use default address: #{address.to_s(16)}"
            end
            address
          end

          def fetch_path
            if @options.has_key?(:path)
              path = @options[:path]
            else
              path = default_path
              logger.warn "No path specified. Use default path: #{path}"
            end
            path
          end

          def initialize_lcd
            @lcd = I2C.create(fetch_path)
            @address = fetch_address
            @backlight = @options.fetch(:backlight, true)

            byte(0x33, OP_CMD)
            byte(0x32, OP_CMD)
            byte(0x06, OP_CMD)
            byte(0x0C, OP_CMD)
            byte(0x28, OP_CMD)
            byte(0x01, OP_CMD)
            sleep(DELAY)
          end

          def backlight_mode
            return BACKLIGHT_ON if @backlight
            BACKLIGHT_OFF
          end

          def write_line(message, line)
            message = '' unless message
            message = message.ljust(WIDTH, ' ')
            byte(line, OP_CMD)
            WIDTH.times.each { |pos| byte(message[pos].ord, OP_CHR) }
          end

          def write(bits)
            @lcd.write(@address, bits)
          end

          def byte(bits, mode)
            high = mode | (bits & 0xF0) | backlight_mode
            low = mode | (bits << 4) & 0xF0 | backlight_mode

            write(high)
            toggle(high)

            write(low)
            toggle(low)
          end

          def toggle(bits)
            sleep(DELAY)
            write(bits | ENABLE)
            sleep(PULSE)
            write(bits & ~ENABLE)
            sleep(DELAY)
          end
        end
      end
    end
  end
end
