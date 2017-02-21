require 'tamashii/agent/adapter/base'
require 'tamashii/agent/device/pi_buzzer'
require 'tamashii/agent/device/fake_buzzer'

module Tamashii
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
