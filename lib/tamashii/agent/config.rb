require 'tamashii/common'
require 'tamashii/client'
module Tamashii
  module Agent
    class Config
      class << self
        def instance
          @instance ||= Config.new
        end

        def respond_to_missing?(name, _all = false)
          super
        end

        def method_missing(name, *args, &block)
          # rubocop:disable Metrics/LineLength
          return instance.send(name, *args, &block) if instance.respond_to?(name)
          # rubocop:enable Metrics/LineLength
          super
        end
      end

      include Tamashii::Configurable

      AUTH_TYPES = [:none, :token]

      config :default_components, default: {networking: {class_name: :Networking, options: {}}}
      config :connection_timeout, default: 3

      config :env, deafult: nil
      config :token

      config :localtime, default: "+08:00"

      config :lcd_animation_delay, default: 1


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
        Client.config.log_file = value
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

      def env(env = nil)
        return Tamashii::Environment.new(self[:env]) if env.nil?
        self.env = env.to_s
      end
    end
  end
end
