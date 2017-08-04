module Tamashii
  module Agent
    module Device
      # :nodoc:
      class FakeLCD
        include Common::Loggable
        WIDTH = 16
        LINE_COUNT = 2

        attr_accessor :backlight

        def initialize
          @backlight = true
        end

        def print_message(message)
          lines = message.lines.map{|l| l.delete("\n")}
          logger.info "LCD Display(BACKLIGHT: #{@backlight}):"
          lines.take(LINE_COUNT).each_with_index { |line_text, line| print_line(line_text, line) }
        end

        def print_line(message, line)
          message = '' unless message
          message = message.ljust(WIDTH, ' ')
          message.split('').take(WIDTH).join('')
          logger.info "Line #{line}: #{message}"
        end
      end
    end
  end
end
