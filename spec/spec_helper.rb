$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "codeme/agent"
require 'tempfile'
require 'simplecov'

SimpleCov.start

Codeme::Agent.config do
  log_file Tempfile.new.path
end
