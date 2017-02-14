require 'codeme/agent/common'
require 'codeme/agent/handler/base'

module Codeme
  module Agent
    module Handler
      class System < Base
        def resolve(data)
          @master.send_event(EVENT_SYSTEM_COMMAND, type.to_s)
        end
      end
    end
  end
end
