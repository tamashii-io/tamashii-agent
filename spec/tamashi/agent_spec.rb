require "spec_helper"

describe Tamashi::Agent do
  it "has a version number" do
    expect(Tamashi::Agent::VERSION).not_to be nil
  end

  it "can get config" do
    expect(Tamashi::Agent.config).to be(Tamashi::Agent::Config)
  end

  it "can get logger" do
    expect(Tamashi::Agent.logger).to be_instance_of(Tamashi::Logger)
  end

end
