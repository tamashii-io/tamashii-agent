require "codeme/agent/version"
require "codeme/agent/master"
require "codeme/agent/logger"

module Codeme
  module Agent
    def self.logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end
