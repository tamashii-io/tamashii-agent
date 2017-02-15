require 'json'
module Tamashi
  module Agent
    class RequestPool
      class Request
        attr_accessor :id
        attr_accessor :ev_type
        attr_accessor :ev_body
        attr_accessor :state

        STATE_PENDING = :pending
        STATE_SENT = :sent

        def initialize(ev_type, ev_body, id)
          @ev_type = ev_type
          @ev_body = ev_body
          @id = id
          @state = STATE_PENDING
        end

        def wrap_body
          {
            id: @id,
            ev_body: @ev_body
          }.to_json
        end

        def sent!
          @state = STATE_SENT
        end

        def sent?
          @state == STATE_SENT
        end
      end
    end
  end
end
