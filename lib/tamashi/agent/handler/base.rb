require 'tamashi/common'

module Tamashi
  module Agent
    module Handler
      class Base < Tamashi::Handler
        def initialize(*args, &block)
          super(*args, &block)
          @connection = self.env[:connection]
          @master = @connection.master
        end
      end
    end
  end
end
