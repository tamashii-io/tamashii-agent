require 'tamashii/common'
require 'tamashii/client'
module Tamashii
  module Agent
    class Config < Tamashii::Config
      AUTH_TYPES = [:none, :token]

      register :default_components, {networking: {class_name: :Networking, options: {}}}
      register :connection_timeout, 3

      register :localtime, "+08:00"

      register :lcd_animation_delay, 1


      def auth_type(type = nil)
        return @auth_type ||= :none if type.nil?
        return unless AUTH_TYPES.include?(type)
        @auth_type = type.to_sym
      end

      def log_level(level = nil)
        return Agent.logger.level if level.nil?
        Client.config.log_level(level)
        Agent.logger.level = level
      end

      def log_file(value = nil)
        return @log_file ||= STDOUT if value.nil?
        Client.config.log_file(value)
        @log_file = value
      end

      [:use_ssl, :host, :port, :entry_point].each do |method_name|
        define_method(method_name) do |*args|
          Tamashii::Client.config.send(method_name, *args)
        end
      end

      def add_component(name, class_name, options = {},  &block)
        self.components[name] = {class_name: class_name, options: options, block: block}  
      end

      def remove_component(name)
        self.components.delete(name)
      end

      def components
        @components ||= self.default_components.clone
      end
    end
  end
end
