$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'tempfile'
require 'simplecov'

SimpleCov.start

require "codeme/agent"

Codeme::Agent.config do
  log_file Tempfile.new.path
  env "test"
end

