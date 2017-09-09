require 'tamashii/common'

module Tamashii
  module Agent
    module Handler
      class Base < Tamashii::Handler
        def initialize(*args, &block)
          super(*args, &block)
          @networking = self.env[:networking]
          @master = self.env[:master]
        end
      end
    end
  end
end
