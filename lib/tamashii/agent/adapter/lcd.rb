require 'tamashii/agent/adapter/base'
require 'tamashii/agent/device/lcd'
require 'tamashii/agent/device/fake_lcd'

module Tamashii
  module Agent
    module Adapter
      # :nodoc:
      class LCD < Base
        class << self
          def real_class
            Device::LCD
          end

          def fake_class
            Device::FakeLCD
          end
        end
      end
    end
  end
end
