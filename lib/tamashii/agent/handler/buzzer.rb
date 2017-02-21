require 'tamashii/agent/common'
require 'tamashii/agent/handler/base'

module Tamashii
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
