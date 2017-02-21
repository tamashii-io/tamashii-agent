require "spec_helper"

describe Tamashii::Agent do
  it "has a version number" do
    expect(Tamashii::Agent::VERSION).not_to be nil
  end

  it "can get config" do
    expect(Tamashii::Agent.config).to be(Tamashii::Agent::Config)
  end

  it "can get logger" do
    expect(Tamashii::Agent.logger).to be_instance_of(Tamashii::Logger)
  end

end
