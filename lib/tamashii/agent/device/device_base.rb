require 'pi_piper'
require 'tamashii/agent/common'

module Tamashii
  module Agent
    module Device
      class DeviceBase
        include Common::Loggable

        class OptionNotFoundError < RuntimeError; end

        def initialize(component, options = {})
          @component = component
          @options = options
        end

        def shutdown
          logger.warn "Device '#{self.class}' does not implement a shutdown method"
        end

        def fetch_option(name, default_value)
          fetch_option!(name)
        rescue OptionNotFoundError => e
          logger.warn "No #{name} specified in options. Use default #{name}: #{default_value}"
          return default_value
        end

        def fetch_option!(name)
          if @options.has_key?(name)
            return @options[name]
          else
            raise OptionNotFoundError, "#{name} not found in option"
          end
        end

        def unexport_pin(pin_number)
          raise ArgumentErrorm, "pin number must be a integer" unless pin_number.is_a? Integer
          if PiPiper::Platform.driver == PiPiper::Bcm2835
            PiPiper::Platform.driver.unexport_pin(pin_number)
          else
            logger.warn "Underlying driver #{PiPiper::Platform.driver} does not support unexporting"
          end
        end
      end
    end
  end
end
