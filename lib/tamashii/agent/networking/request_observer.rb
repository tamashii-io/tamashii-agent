require 'tamashii/common'

module Tamashii
  module Agent
    class Networking
      class RequestObserver

        include Common::Loggable
        def initialize(networking, id, ev_type, ev_body, future)
          @networking = networking
          @id = id
          @ev_type = ev_type
          @ev_body = ev_body
          @future = future
        end

        def update(time, ev_data, reason)
          if @future.fulfilled?
            res_ev_type = ev_data[:ev_type]
            res_ev_body = ev_data[:ev_body]
            case res_ev_type
            when Type::RFID_RESPONSE_JSON
              logger.debug "Handled: #{res_ev_type}: #{res_ev_body}"
              @networking.handle_card_result(JSON.parse(res_ev_body))
            else
              logger.warn "Unhandled packet result: #{res_ev_type}: #{res_ev_body}"
            end
          else
            logger.error "#{@id} Failed with #{reason}"
            @networking.on_request_timeout(@ev_type, @ev_body)
          end
        end
      end
    end
  end
end



