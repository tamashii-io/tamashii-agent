require 'tamashii/agent/event'
require 'tamashii/agent/handler/base'

module Tamashii
  module Agent
    module Handler
      class Buzzer < Base
        def resolve(data)
          @master.send_event(Event.new(Event::BEEP, data))
        end
      end
    end
  end
end
