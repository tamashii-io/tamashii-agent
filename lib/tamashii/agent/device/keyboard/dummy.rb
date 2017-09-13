require 'pi_piper'
require 'tamashii/agent/device/keyboard/base'

module Tamashii
  module Agent
    module Device
      module Keyboard
        class Dummy < Base
          def initialize_hardware
            @last_report = Time.now
            logger.debug "Initialized"
          end
          
          def finalize_hardware
            logger.debug "Finalized"
          end
          
          def default_number_of_keys
            8
          end

          def read_key
            if (Time.now - @last_report) > (3 + rand)
              @last_report = Time.now
              key = rand(@number_of_keys)
              logger.debug "Fake key generated: #{key}"
              @number_of_keys.times do |testing_key|
                if testing_key == key
                  mark_key_down(testing_key)
                else
                  mark_key_up(testing_key)
                end
              end
              return key
            else
              return nil
            end
          end
        end
      end
    end
  end
end
