require 'codeme/common'
require 'codeme/agent/request_pool'

module Codeme
  module Agent
    module Handler
      class RequestPoolResponse < Codeme::Handler
        def resolve(data)
          connection = self.env[:connection]
          connection.request_pool.add_response(RequestPool::Response.new(self.type, data))
        end
      end
    end
  end
end
