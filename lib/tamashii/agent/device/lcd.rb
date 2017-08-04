require 'i2c'

module Tamashii
  module Agent
    module Device
      # :nodoc:
      class LCD
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

        def initialize
          @lcd = I2C.create(Config.lcd_path)
          @address = Config.lcd_address
          @backlight = true

          byte(0x33, OP_CMD)
          byte(0x32, OP_CMD)
          byte(0x06, OP_CMD)
          byte(0x0C, OP_CMD)
          byte(0x28, OP_CMD)
          byte(0x01, OP_CMD)
          sleep(DELAY)
        end

        def print_message(message)
          lines = message.lines.map{|l| l.delete("\n")}
          LINE_COUNT.times.each { |line| print_line(lines[line], line) }
        end

        def print_line(message, line)
          write_line(message, LINES[line])
        end

        private

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
