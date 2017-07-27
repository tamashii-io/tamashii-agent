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

        def print_message(message)
          lines = message.lines.map{|l| l.delete("\n")}
          puts "LCD Display(BACKLIGHT: #{@backlight}):"
          puts lines.take(2).map { |line| print_line(line) }.join("\n")
        end

        private

        def print_line(message)
          message = '' unless message
          message = message.ljust(WIDTH, ' ')
          message.split('').take(WIDTH).join('')
        end
      end
    end
  end
end
