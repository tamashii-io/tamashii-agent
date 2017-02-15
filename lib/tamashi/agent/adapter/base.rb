require 'tamashi/common'
require 'tamashi/agent/config'

module Tamashi
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
