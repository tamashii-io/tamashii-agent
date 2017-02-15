require 'tamashi/agent/handler/base'
require 'tamashi/agent/request_pool'

module Tamashi
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
