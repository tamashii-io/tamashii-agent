require 'codeme/common'

module Codeme
  module Agent
    module Handler
      class Base < Codeme::Handler
        def initialize(*args, &block)
          super(*args, &block)
          @connection = self.env[:connection]
          @master = @connection.master
        end
      end
    end
  end
end
