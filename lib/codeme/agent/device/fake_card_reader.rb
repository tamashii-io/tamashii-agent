require 'codeme/agent/common'
module Codeme
  module Agent
    module Device
      class FakeCardReader
        include Common::Loggable

        def initialize(*args)
          logger.debug "Initialized"
        end

        def picc_request(*args)
        end

        def picc_select(*args)
        end

        def picc_halt(*args)
        end
      end
    end
  end
end

