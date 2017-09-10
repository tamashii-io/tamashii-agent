require 'tamashii/agent/device/card_reader/base'

module Tamashii
  module Agent
    module Device
      module CardReader
        class Dummy < Base
          def initialize(*args)
            super
            logger.debug "Initialized"
            @last_time = Time.now
          end

          def poll_uid
            if Time.now - @last_time > 2
              @last_time = Time.now
              if rand > 0.5
                uid = Array.new(4){ rand(256)}
                logger.debug "Fake Card Generated: #{uid}"
                return uid
              else
                return nil
              end
            else
              return nil
            end
          end

          def shutdown
            logger.debug "Stopped"
          end
        end
      end
    end
  end
end

