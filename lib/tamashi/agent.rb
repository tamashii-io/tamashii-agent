require "tamashi/common"
require "tamashi/agent/version"
require "tamashi/agent/master"
require "tamashi/agent/config"


module Tamashi
  module Agent
    def self.config(&block)
      return Config.class_eval(&block) if block_given?
      Config
    end

    def self.logger
      @logger ||= Tamashi::Logger.new(Config.log_file)
    end
  end
end
