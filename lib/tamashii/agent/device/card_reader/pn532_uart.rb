require 'nfc'
require 'tamashii/agent/device/card_reader/base'

module Tamashii
  module Agent
    module Device
      module CardReader
        class Pn532Uart < Base
          def initialize(*args)
            super
            @ctx = NFC::Context.new
            @dev = @ctx.open "pn532_uart:#{fetch_option(:path, default_path)}"
            @card_type = @options[:card_type] || :felica
            logger.info "Card type enabled: #{@card_type}"
          end

          def default_path
            "/dev/ttyAMA0"
          end

          def poll_uid
            tag = @dev.poll(@card_type)
            if tag && !tag.is_a?(Integer)
              return tag.uid
            else
              return nil
            end
          rescue => e
            logger.error "Error when reading card: #{e.message}"
            return :error
          end

          def shutdown
            @dev.close
            @dev = nil
          end
        end
      end
    end
  end
end

