require 'mfrc522'
require 'concurrent'

require 'tamashii/agent/component'
require 'tamashii/agent/event'
require 'tamashii/agent/adapter/card_reader'


module Tamashii
  module Agent
    class CardReader < Component

      ERROR_RESET_TIMER = 5

      def initialize(name, master, options = {})
        super
        @reader = Adapter::CardReader.object
        logger.debug "Using card_reader instance: #{@reader.class}"
      end

      def reset_error_timer
        return unless @error_timer_task
        @error_timer_task.cancel
        @error_timer_task = nil
        logger.info "Error timer is reset"
      end

      def set_error_timer
        return if @error_timer_task && !@error_timer_task.unscheduled?
        logger.info "Error timer is set"
        @error_timer_task = Concurrent::ScheduledTask.execute(ERROR_RESET_TIMER) { restart_current_component_async }
      end

      # override
      def worker_loop
        loop do
          if !handle_new_event(true)
            # no event available
            sleep 0.1
          end
          if handle_card
            # card is sent, sleep to prevent duplicate sent
            sleep 1.0
          else
            # no card available
            sleep 0.1
          end
        end
      end

      def handle_card
        # read card
        return false unless @reader.picc_request(MFRC522::PICC_REQA)

        begin
          uid, sak = @reader.picc_select
          process_uid(uid.join("-"))
          reset_error_timer
        rescue CommunicationError, UnexpectedDataError => e
          logger.error "Error when selecting card: #{e.message}"
          set_error_timer
        rescue => e
          logger.error "GemError when selecting card: #{e.message}"
          set_error_timer
        end
        @reader.picc_halt
        true
      end

      def process_uid(uid)
        logger.info "New card detected, UID: #{uid}"
        @master.send_event(Event.new(Event::CARD_DATA, uid))
      end

      # override
      def process_event(event)
        # silent is gold
      end

      def clean_up
        super
        @reader.shutdown
      end
    end
  end
end

