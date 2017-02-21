require 'tamashii/agent/adapter/base'
require 'tamashii/agent/device/fake_card_reader'

module Tamashii
  module Agent
    module Adapter
      class CardReader < Base
        class << self
          def real_class
            MFRC522
          end

          def fake_class
            Device::FakeCardReader
          end
        end
      end
    end
  end
end
