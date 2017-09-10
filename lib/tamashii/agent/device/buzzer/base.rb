require 'tamashii/agent/common'
require 'tamashii/agent/device/device_base'

module Tamashii
  module Agent
    module Device
      module Buzzer
        class Base < DeviceBase
          include Common::Loggable

          def play_ok
            raise NotImplementedError, "play_ok"
          end

          def play_no
            raise NotImplementedError, "play_no"
          end

          def play_error
            raise NotImplementedError, "play_error"
          end
        end
      end
    end
  end
end
