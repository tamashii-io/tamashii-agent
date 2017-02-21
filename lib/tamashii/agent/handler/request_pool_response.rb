require 'tamashii/agent/handler/base'
require 'tamashii/agent/request_pool'

module Tamashii
  module Agent
    module Handler
      class RequestPoolResponse < Base
        def resolve(data)
          @connection.request_pool.add_response(RequestPool::Response.new(self.type, data))
        end
      end
    end
  end
end
