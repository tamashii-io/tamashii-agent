require 'spec_helper'

RSpec.describe Tamashi::Agent::Device::FakeBuzzer do
  it "can stop" do
    expect(subject).to respond_to(:stop)
  end
  it "can play ok" do
    expect(subject).to respond_to(:play_ok)
  end
  it "can play no" do
    expect(subject).to respond_to(:play_no)
  end
  it "can play error" do
    expect(subject).to respond_to(:play_error)
  end
end
