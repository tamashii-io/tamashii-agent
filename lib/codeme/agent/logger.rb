module Codeme
  module Agent
    module Logger
      def log(msg)
        puts "[#{self.class}] #{msg}" if @enable_log
      end

      def enable_log(val)
        @enable_log
      end

      def enable_log=(val)
        @enable_log = val
      end
    end
  end
end
