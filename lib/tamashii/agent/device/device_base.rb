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
      end
    end
  end
end
