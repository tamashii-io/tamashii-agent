require 'tamashii/config'

require "tamashii/agent/version"
require "tamashii/agent/master"
require "tamashii/agent/config"


module Tamashii
  module Agent
    def self.config(&block)
      return instance_exec(Config.instance, &block) if block_given?
      Config
    end

    def self.logger
      @logger ||= Tamashii::Logger.new(Config.log_file)
    end
  end
end

Tamashii::Hook.after(:config) do |config|
  config.register(:agent, Tamashii::Agent.config)
end
