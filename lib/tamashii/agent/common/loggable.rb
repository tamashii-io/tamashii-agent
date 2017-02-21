require 'tamashii/agent'

module Tamashii
  module Agent
    module Common
      module Loggable
        def logger
          Agent.logger.progname = self.progname
          Agent.logger
        end

        def progname
          @progname ||= ("%-10s" % self.class.to_s.split(":")[-1])
        end
      end
    end
  end
end
