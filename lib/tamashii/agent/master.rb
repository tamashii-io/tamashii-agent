require 'tamashii/agent/common'
require 'tamashii/agent/networking'
require 'tamashii/agent/lcd'
require 'tamashii/agent/buzzer'
require 'tamashii/agent/card_reader'
require 'tamashii/agent/event'

require 'thread'

module Tamashii
  module Agent
    class Master < Component

      attr_reader :serial_number

      def initialize
        super(:master, self)
        logger.info "Starting Tamashii::Agent #{Tamashii::Agent::VERSION} in #{Config.env} mode"
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
        Config.components.each do |name, params|
          create_component(name, params) 
        end
      end

      def create_component(name, params)
        klass = Agent.const_get(params[:class_name])
        logger.info "Starting component #{name}:#{klass}"
        c = klass.new(name, self, params[:options])
        c.instance_eval(&params[:block]) if params[:block] 
        yield c if block_given?
        c.run
        @components[name] = c
      end

      def restart_component(name)
        if old_component = @components[name]
          params = Config.components[name]
          logger.info "Stopping component: #{name}"
          old_component.stop # TODO: set timeout for stopping?
          logger.info "Restarting component: #{name}"
          create_component(name, params)
        else
          logger.error "Restart component failed: unknown component #{name}"
        end
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
          broadcast_event(Event.new(Event::LCD_MESSAGE, "Fatal Error\nConnection Error"))
        when Event::RESTART_COMPONENT
          restart_component(event.body)
        else
          broadcast_event(event)
        end
      end

      def show_message(message)
        logger.info message
        broadcast_event(Event.new(Event::LCD_MESSAGE, message))
        sleep 1
      end

      def system_reboot
        show_message "Rebooting"
        system("reboot &")
      end

      def system_poweroff
        show_message "Powering  Off"
        system("poweroff &")
      end

      def system_restart
        show_message "Restarting"
        system("systemctl restart tamashii-agent.service &")
      end

      def system_update
        show_message("Updating")
        system("gem update tamashii-agent")
        system_restart
      end

      # override
      def stop
        super
        @components.each_value do |c|
          c.stop
        end
        logger.info "Master stopped"
      end


      def broadcast_event(event)
        @components.each_value do |c|
          c.send_event(event)
        end
      end
    end
  end
end
