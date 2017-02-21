require 'tamashii/common'

module Tamashii
  module Agent
    module Handler
      class Base < Tamashii::Handler
        def initialize(*args, &block)
          super(*args, &block)
          @connection = self.env[:connection]
          @master = @connection.master
        end
      end
    end
  end
end
