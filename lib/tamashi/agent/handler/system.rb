require 'tamashi/agent/common'
require 'tamashi/agent/handler/base'

module Tamashi
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
