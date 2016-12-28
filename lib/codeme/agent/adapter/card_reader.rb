require 'codeme/agent/adapter/base'
require 'codeme/agent/device/fake_card_reader'

module Codeme
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
