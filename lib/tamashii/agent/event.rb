module Tamashii
  module Agent
    class Event
      
      attr_reader :type, :body

      def initialize(type, body)
        @type = type
        @body = body
        self.freeze
      end
    end
  end
end
