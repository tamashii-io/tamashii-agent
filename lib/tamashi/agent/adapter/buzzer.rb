require 'tamashi/agent/adapter/base'
require 'tamashi/agent/device/pi_buzzer'
require 'tamashi/agent/device/fake_buzzer'

module Tamashi
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
