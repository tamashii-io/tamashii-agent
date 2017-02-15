require 'tamashi/agent/common'
require 'tamashi/agent/handler/base'

module Tamashi
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
