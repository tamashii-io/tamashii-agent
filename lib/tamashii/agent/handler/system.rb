require 'tamashii/agent/common'
require 'tamashii/agent/handler/base'

module Tamashii
  module Agent
    module Handler
      class System < Base
        def resolve(data)
          @master.send_event(Event.new(EVENT_SYSTEM_COMMAND, type.to_s))
        end
      end
    end
  end
end
