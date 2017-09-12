require 'mfrc522'
require 'tamashii/agent/device/card_reader/base'

module Tamashii
  module Agent
    module Device
      module CardReader
        class Mfrc522Spi < Base

          def initialize(*args)
            super
            @reader = MFRC522.new(fetch_option(:reset_pin, default_reset_pin))
          end

          def default_reset_pin
            24
          end

          def poll_uid
            # check antenna
            return nil unless @reader.picc_request(MFRC522::PICC_REQA)

            # read uid
            uid = nil
            begin
              uid, sak = @reader.picc_select
            rescue CommunicationError, UnexpectedDataError => e
              logger.error "Error when selecting card: #{e.message}"
              uid = :error
            rescue => e
              uid = :error
              logger.error "GemError when selecting card: #{e.message}"
            ensure
              @reader.picc_halt
            end
            uid
          end

          def shutdown
            @reader.shutdown
          end
        end
      end
    end
  end
end

