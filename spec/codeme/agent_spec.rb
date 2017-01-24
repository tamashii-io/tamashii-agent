require "spec_helper"

describe Codeme::Agent do
  it "has a version number" do
    expect(Codeme::Agent::VERSION).not_to be nil
  end

  it "can get config" do
    expect(Codeme::Agent.config).to be(Codeme::Agent::Config)
  end

  it "can get logger" do
    expect(Codeme::Agent.logger).to be_instance_of(Codeme::Logger)
  end

end
