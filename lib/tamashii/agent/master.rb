require 'tamashii/agent/connection'
require 'tamashii/agent/buzzer'
require 'tamashii/agent/card_reader'
require 'tamashii/agent/event'

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
      def process_event(event)
        super
        case event.type
        when Event::SYSTEM_COMMAND
          logger.info "System command code: #{event.body}"
          case event.body.to_i
          when Tamashii::Type::REBOOT
            system_reboot
          when Tamashii::Type::POWEROFF
            system_poweroff
          when Tamashii::Type::RESTART
            system_restart
          when Tamashii::Type::UPDATE
            system_update
          end
        when Event::CONNECTION_NOT_READY
          broadcast_event(Event.new(Event::BEEP, "error"))
        else
          broadcast_event(event)
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


      def broadcast_event(event)
        @components.each_value do |c|
          c.send_event(event)
        end
      end
    end
  end
end
