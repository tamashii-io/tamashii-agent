require 'json'
module Codeme
  module Agent


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

    class Response
      attr_accessor :ev_type, :ev_body, :id

      def initialize(ev_type, wrapped_body)
        @ev_type = ev_type
        data = JSON.parse(wrapped_body)
        @id = data["id"]
        @ev_body = data["ev_body"]
      end
      
    end

    class RequestPool

      attr_accessor :on_request_timedout
      attr_accessor :on_request_meet
      attr_accessor :on_send_request

      def initialize
        @pool = {}
        @on_request_timedout = nil
        @on_request_meet = nil
        @on_send_request = nil
      end

      def add_request(req, timedout = 3)
        @pool[req.id] = {req: req, timestamp: Time.now, timedout: timedout}
        try_send_request(req)
      end

      def add_response(res)
        # find the same id
        req_data = @pool[res.id]
        if req_data
          @pool.delete(res.id)
          if @on_request_meet
            @on_request_meet.call(req_data[:req], res)
          end
        else
          # unmatched response
          # discard
          false
        end
      end

      def update
        process_pending
        check_timedout
      end
      
      def check_timedout
        now = Time.now
        @pool.each do |id, req_data|
          if now - req_data[:timestamp] >= req_data[:timedout]
            # timedout
            @pool.delete(id)
            if @on_request_timedout
             @on_request_timedout.call(req_data[:req])
            end
          end
        end
      end

      def process_pending
        @pool.each_value do |data|
          try_send_request(data[:req]) unless data[:req].sent?
        end
      end

      def try_send_request(req)
        if @on_send_request
          if @on_send_request.call(req)
            req.sent!
          end
        end
      end
    end
  end
end


