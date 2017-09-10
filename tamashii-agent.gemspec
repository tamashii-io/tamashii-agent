# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tamashii/agent/version'

Gem::Specification.new do |spec|
  spec.name          = "tamashii-agent"
  spec.version       = Tamashii::Agent::VERSION
  spec.authors       = ["蒼時弦也", "Liang-Chi Tseng", "五倍紅寶石"]
  spec.email         = ["elct9620@frost.tw", "lctseng@cs.nctu.edu.tw", "hi@5xruby.tw"]

  spec.summary       = %q{The agent module for RubyConfTW checkin system.}
  spec.description   = %q{The agent module for RubyConfTW checkin system.}
  spec.homepage      = "https://github.com/tamashii-io/tamashii-agent"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    #spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "pry"


  spec.add_runtime_dependency "tamashii-common", ">=0.1.6"
  spec.add_runtime_dependency "tamashii-client"
  spec.add_runtime_dependency "websocket-driver"
  spec.add_runtime_dependency "nio4r"
  spec.add_runtime_dependency "pi_piper"
  spec.add_runtime_dependency "tamashii-mfrc522"
  spec.add_runtime_dependency "i2c"
  spec.add_runtime_dependency "aasm"
  spec.add_runtime_dependency "concurrent-ruby"
end
