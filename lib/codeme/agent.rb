require "codeme/agent/version"
require "codeme/agent/master"
require "codeme/agent/logger"
require "codeme/agent/config"

module Codeme
  module Agent
    def self.config(&block)
      return Config.class_eval(&block) if block_given?
      Config
    end

    def self.logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end
