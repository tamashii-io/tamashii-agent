require 'tamashi/agent/common'
require 'tamashi/agent/request_pool/request'
require 'tamashi/agent/request_pool/response'


module Tamashi
  module Agent
    class RequestPool
      include Common::Loggable
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
          logger.warn "WARN: un-handled event: #{sym}"
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
          logger.warn "WARN: un-matched response (id=#{res.id}): #{res.inspect}"
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


