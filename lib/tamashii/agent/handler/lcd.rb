require 'tamashii/agent/event'
require 'tamashii/agent/handler/base'

module Tamashii
  module Agent
    module Handler
      class LCD < Base
        def resolve(data)
          case type
          when Type::LCD_MESSAGE
            @master.send_event(Event.new(Event::LCD_MESSAGE, data))
          when Type::LCD_SET_IDLE_TEXT
            @master.send_event(Event.new(Event::LCD_SET_IDLE_TEXT, data))
          end
        end
      end
    end
  end
end
