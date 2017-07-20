require 'tamashii/agent/event'
require 'tamashii/agent/handler/base'

module Tamashii
  module Agent
    module Handler
      class System < Base
        def resolve(data)
          @master.send_event(Event.new(Event::SYSTEM_COMMAND, type.to_s))
        end
      end
    end
  end
end
