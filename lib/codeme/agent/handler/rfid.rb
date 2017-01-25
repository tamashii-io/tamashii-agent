require 'codeme/common'
require 'codeme/agent/request_pool'

module Codeme
  module Agent
    module Handler
      class RFID < Codeme::Handler
        def resolve(data)
          connection = self.env[:connection]
          connection.logger.debug "echo data: #{data}"
          connection.request_pool.add_response(RequestPool::Response.new(self.type, data))
        end
      end
    end
  end
end
