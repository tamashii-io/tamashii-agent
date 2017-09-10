require 'tamashii/agent/device/device_base'

module Tamashii
  module Agent
    module Device
      module CardReader
        class Base < DeviceBase
          def poll_uid
            raise NotImplementedError, "poll_uid"
          end
        end
      end
    end
  end
end

