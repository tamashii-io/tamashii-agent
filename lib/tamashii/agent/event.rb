module Tamashii
  module Agent
    class Event

      BEEP = 1
      SYSTEM_COMMAND = 2
      AUTH_RESULT = 3
      CARD_DATA = 4
      LCD_MESSAGE = 5
      LCD_SET_IDLE_TEXT = 6

      RESTART_COMPONENT = 254
      CONNECTION_NOT_READY = 255

      
      
      attr_reader :type, :body

      def initialize(type, body)
        @type = type
        @body = body
        self.freeze
      end

      def ==(other)
        @type == other.type && @body == other.body
      end
    end
  end
end
