require 'mfrc522'

require 'codeme/agent/component'

module Codeme
  module Agent
    class CardReader < Component
      def initialize(master)
        super()
        @master = master
        @reader = MFRC522.new
      end

      # override
      def worker_loop
        loop do
          handle_io
          handle_card
        end
      end

      def handle_io
        ready = @selector.select(0.1)
        ready.each { |m| m.value.call } if ready
      end

      def handle_card
        # read card
        return unless @reader.picc_request(MFRC522::PICC_REQA)

        begin
          uid, sak = @reader.picc_select
          process_uid(uid.join("-"))
        rescue CommunicationError, UnexpectedDataError => e
          logger.error "Error when selecting card: #{e.message}"
        rescue => e
          logger.error "GemError when selecting card: #{e.message}"
        end

        logger.debug "picc halt #{@reader.picc_halt}"
      end

      def process_uid(uid)
        logger.info "New card detected, UID: #{uid}"
        @master.send_event(EVENT_CARD_DATA, uid)
      end

      # override
      def process_event(ev_type, ev_body)
        # silent is gold
      end
    end
  end
end

