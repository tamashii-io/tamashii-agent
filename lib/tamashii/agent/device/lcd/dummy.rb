require 'tamashii/agent/device/lcd/base'

module Tamashii
  module Agent
    module Device
      module Lcd
        class Dummy < Base
          def line_count
            2
          end

          def width
            16
          end

          def print_line(message, line)
            message = '' unless message
            message = message.ljust(width, ' ')
            message.split('').take(width).join('')
            logger.debug "Line #{line}: #{message}"
          end

          def shutdown
            logger.debug "Stopped"
          end
        end
      end
    end
  end
end
