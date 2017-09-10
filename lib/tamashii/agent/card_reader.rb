require 'concurrent'

require 'tamashii/agent/component'
require 'tamashii/agent/event'

module Tamashii
  module Agent
    class CardReader < Component

      ERROR_RESET_TIMER = 5

      def initialize(name, master, options = {})
        super
        @reader = initialize_device
      end

      def default_device_name
        'Dummy'
      end

      def get_device_class_name(device_name)
        "CardReader::#{device_name}"
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
        uid = @reader.poll_uid
        case uid
        when nil
          return false
        when :error
          set_error_timer
          return false
        else
          process_uid(uid)
          reset_error_timer
          return true
        end
      end

      def process_uid(uid)
        logger.info "New card detected, UID: #{uid}"
        @master.send_event(Event.new(Event::CARD_DATA, uid.join('-')))
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

