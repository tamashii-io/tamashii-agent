require 'tamashii/agent/common'
module Tamashii
  module Agent
    module Device
      class FakeBuzzer
        include Common::Loggable

        def initialize
          logger.debug "Initialized"
        end

        def play_ok
          logger.debug "Played: OK"
        end

        def play_no
          logger.debug "Played: No"
        end

        def play_error
          logger.debug "Played: Error"
        end

        def stop
          logger.debug "Stopped"
        end
      end
    end
  end
end
