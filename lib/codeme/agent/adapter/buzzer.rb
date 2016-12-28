require 'codeme/agent/adapter/base'
require 'codeme/agent/device/pi_buzzer'
require 'codeme/agent/device/fake_buzzer'

module Codeme
  module Agent
    module Adapter
      class Buzzer < Base
        class << self
          def real_class
            Device::PIBuzzer
          end

          def fake_class
            Device::FakeBuzzer
          end
        end
      end
    end
  end
end
