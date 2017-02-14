require 'codeme/agent/connection'
require 'codeme/agent/buzzer'
require 'codeme/agent/card_reader'

require 'thread'

module Codeme
  module Agent
    class Master < Component

      attr_reader :serial_number

      def initialize(host, port)
        super()
        logger.info "Starting Codeme::Agent in #{Config.env} mode"
        @host = host
        @port = port
        @serial_number = get_serial_number
        logger.info "Serial number: #{@serial_number}"
        create_components
      end

      def get_serial_number
        File.open("/proc/cpuinfo") do |f|
          content = f.read
          if content =~ /Serial\s*:\s*(\w+)/
            return $1
          end
        end
        # Cannot get serial number
        if Config.env == "test"
          return "TEST_PID_#{Process.pid}"
        else
          return nil
        end
      end

      def create_components
        @components = {}
        @components[:connection] = create_component(Connection, self, @host, @port)
        @components[:buzzer] = create_component(Buzzer)
        @components[:card_reader] = create_component(CardReader, self)
      end

      def create_component(class_name, *args)
        c = class_name.new(*args)
        logger.info "Starting component: #{class_name}"
        yield c if block_given?
        c.run
        c
      end

      # override
      def process_event(ev_type, ev_body)
        super
        case ev_type
        when EVENT_SYSTEM_COMMAND
          logger.info "System command code: #{ev_body}"
          case ev_body.to_i
          when Codeme::Type::REBOOT
            system_reboot
          when Codeme::Type::POWEROFF
            system_poweroff
          when Codeme::Type::RESTART
            system_restart
          when Codeme::Type::UPDATE
            logger.error "Update is not implenented"
          end
        when EVENT_CONNECTION_NOT_READY
          broadcast_event(EVENT_BEEP, "error")
        else
          broadcast_event(ev_type, ev_body)
        end
      end

      def system_reboot
        logger.info "Rebooting..."
        system("reboot &")
      end

      def system_poweroff
        logger.info "Powering Off..."
        system("poweroff &")
      end

      def system_restart
        logger.info "Restarting..."
        system("systemctl start codeme-agent.service &")
      end

      # override
      def stop
        super
        @components.each_value do |c|
          c.stop
        end
      end


      def broadcast_event(ev_type, ev_body)
        @components.each_value do |c|
          c.send_event(ev_type, ev_body)
        end
      end
    end
  end
end
