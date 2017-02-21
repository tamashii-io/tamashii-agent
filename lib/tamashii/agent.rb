require "tamashii/common"
require "tamashii/agent/version"
require "tamashii/agent/master"
require "tamashii/agent/config"


module Tamashii
  module Agent
    def self.config(&block)
      return Config.class_eval(&block) if block_given?
      Config
    end

    def self.logger
      @logger ||= Tamashii::Logger.new(Config.log_file)
    end
  end
end
