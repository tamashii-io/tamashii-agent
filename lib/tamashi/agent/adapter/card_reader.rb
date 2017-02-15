require 'tamashi/agent/adapter/base'
require 'tamashi/agent/device/fake_card_reader'

module Tamashi
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
