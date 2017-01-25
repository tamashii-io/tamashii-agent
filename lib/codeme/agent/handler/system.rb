require 'codeme/common'
require 'codeme/agent/request_pool'

module Codeme
  module Agent
    module Handler
      class System < Codeme::Handler
        def resolve(data)
          connection.logger.debug "echo data: #{data}"
        end
      end
    end
  end
end
