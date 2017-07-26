require 'i2c'

module Tamashii
  module Agent
    module Device
      # :nodoc:
      class FakeLCD
        WIDTH = 16

        attr_accessor :backlight

        def initialize
          @backlight = true
        end

        def print(message)
          lines = message.lines
          puts "LCD Display(BACKLIGHT: #{@backlight}):"
          puts lines.take(2).map { |line| print_line(line) }.join("\n")
        end

        private

        def print_line(message)
          message = message.ljust(WIDTH, ' ')
          message.split('').take(WIDTH).join('')
        end
      end
    end
  end
end
