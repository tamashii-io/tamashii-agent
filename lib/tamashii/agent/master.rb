require 'tamashii/agent/connection'
require 'tamashii/agent/buzzer'
require 'tamashii/agent/card_reader'

require 'thread'

module Tamashii
  module Agent
    class Master < Component

      attr_reader :serial_number

      def initialize(host, port)
        super()
        logger.info "Starting Tamashii::Agent #{Tamashii::Agent::VERSION} in #{Config.env} mode"
        @host = host
        @port = port
        @serial_number = get_serial_number
        logger.info "Serial number: #{@serial_number}"
        create_components
      end

      def get_serial_number
        serial = ENV['SERIAL_NUMBER']
        serial = read_serial_from_cpuinfo if serial.nil?
        serial = "#{Config.env}_pid_#{Process.pid}".upcase if serial.nil?
        serial
      end

      def read_serial_from_cpuinfo
        return nil unless File.exists?("/proc/cpuinfo")
        File.open("/proc/cpuinfo") do |f|
          content = f.read
          if content =~ /Serial\s*:\s*(\w+)/
            return $1
          end
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
          when Tamashii::Type::REBOOT
            system_reboot
          when Tamashii::Type::POWEROFF
            system_poweroff
          when Tamashii::Type::RESTART
            system_restart
          when Tamashii::Type::UPDATE
            system_update
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
        system("systemctl restart tamashii-agent.service &")
      end

      def system_update
        logger.info "Updating..."
        system("gem update tamashii-agent")
        system_restart
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
