require 'codeme/common'
require 'codeme/agent/config'

module Codeme
  module Agent
    module Adapter
      class Base
        class << self
          def object(*args, &block)
            current_class.new(*args, &block)
          end

          def current_class
            Config.env == "test" ? fake_class : real_class 
          end

          def real_class
            raise NotImplementedError
          end

          def fake_class
            raise NotImplementedError
          end
        end
      end
    end
  end
end
