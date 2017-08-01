require 'tamashii/agent/common'
module Tamashii
  module Agent
    module Device
      class FakeCardReader
        include Common::Loggable

        def initialize(*args)
          logger.debug "Initialized"
          @last_time = Time.now
        end

        def picc_request(*args)
          if Time.now - @last_time > 2
            @last_time = Time.now
            if rand > 0.5
              logger.debug "Fake Card Generated"
              return true
            else
              return false
            end
          else
            return false
          end
        end

        def picc_select(*args)
          [Array.new(4){ rand(256)}, "sak"]
        end

        def picc_halt(*args)
        end

        def shutdown(*args)
        end
      end
    end
  end
end

