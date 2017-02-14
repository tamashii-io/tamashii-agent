require 'codeme/agent/common'
require 'codeme/agent/handler/base'

module Codeme
  module Agent
    module Handler
      class Buzzer < Base
        def resolve(data)
          @master.send_event(EVENT_BEEP, data)
        end
      end
    end
  end
end
