require 'json'
module Tamashii
  module Agent
    class RequestPool
      class Response
        attr_accessor :ev_type, :ev_body, :id

        def initialize(ev_type, wrapped_body)
          @ev_type = ev_type
          data = JSON.parse(wrapped_body)
          @id = data["id"]
          @ev_body = data["ev_body"]
        end

      end
    end
  end
end
