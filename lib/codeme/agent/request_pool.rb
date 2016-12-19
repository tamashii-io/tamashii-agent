require 'json'
require 'codeme/agent/logger'

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
      include Logger
      def initialize
        @pool = {}
        @handlers = {}
      end

      def set_handler(sym, method)
         @handlers[sym] = method      
      end

      def call_handler(sym, *args)
        if handle?(sym)
          @handlers[sym].call(*args)
        else
          log "WARN: un-handled event: #{sym}"
        end
      end

      def handle?(sym)
        @handlers.has_key? sym
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
          call_handler(:request_meet, req_data[:req], res)
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
            call_handler(:request_timedout, req_data[:req])
          end
        end
      end

      def process_pending
        @pool.each_value do |data|
          try_send_request(data[:req]) unless data[:req].sent?
        end
      end

      def try_send_request(req)
        if handle?(:send_request)
          req.sent! if call_handler(:send_request, req)
        end
      end
    end
  end
end


