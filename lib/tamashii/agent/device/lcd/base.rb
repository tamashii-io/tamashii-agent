require 'tamashii/agent/device/device_base'

module Tamashii
  module Agent
    module Device
      module Lcd
        class Base < DeviceBase
          # default implementation
          def print_message(message)
            lines = message.lines.map{|l| l.delete("\n")}
            line_count.times.each { |line| print_line(lines[line], line) }
          end

          def line_count
            raise NotImplementedError, "line_count"
          end

          def width
            raise NotImplementedError, "width"
          end

          def print_line(message, line)
            raise NotImplementedError, "print_line"
          end
        end
      end
    end
  end
end
