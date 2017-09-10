require 'tamashii/agent/device/buzzer/base'

module Tamashii
  module Agent
    module Device
      module Buzzer
        class Dummy < Base
          def initialize(component, options = {})
            super
            logger.debug "Initialized"
          end

          def play_ok
            logger.debug "Played: OK"
          end

          def play_no
            logger.debug "Played: No"
          end

          def play_error
            logger.debug "Played: Error"
          end

          def stop
            logger.debug "Stopped"
          end
        end
      end
    end
  end
end
