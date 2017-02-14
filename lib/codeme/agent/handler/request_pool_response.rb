require 'codeme/agent/handler/base'
require 'codeme/agent/request_pool'

module Codeme
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
