require 'tamashii/agent/common'

module Tamashii
  module Agent
    module Device
      class DeviceBase
        include Common::Loggable

        def initialize(component, options = {})
          @component = component
          @options = options
        end

        def shutdown
          logger.warn "Device '#{self.class}' does not implement a shutdown method"
        end

        def fetch_option(name, default_value)
          if @options.has_key?(name)
            return @options[name]
          else
            logger.warn "No #{name} specified in options. Use default #{name}: #{default_value}"
            return default_value
          end
        end
      end
    end
  end
end
