require 'codeme/agent/component'

module Codeme
  module Agent
    class CardReader < Component
      def initialize(master)
        super()
        @master = master
        @last_time = Time.now
      end

      # override
      def worker_loop
        loop do
          handle_io
          handle_card
        end
      end

      def handle_io
        ready = @selector.select(0.5)
        ready.each { |m| m.value.call } if ready
      end

      def handle_card
        if Time.now - @last_time > 1.0
          @last_time = Time.now
          @master.send_event(EVENT_CARD_DATA, "New Card At #{Time.now}")
        end
      end

      # override
      def process_event(ev_type, ev_body)
        # silent is gold
      end
    end
  end
end

