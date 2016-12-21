require 'spec_helper'

require 'codeme/agent/pi_buzzer'

RSpec.describe Codeme::Agent::PIBuzzer do
  it "can setup" do
    expect(described_class).to respond_to(:setup)
  end
  it "can stop" do
    expect(described_class).to respond_to(:stop)
  end
  it "can play ok" do
    expect(described_class).to respond_to(:play_ok)
  end
  it "can play no" do
    expect(described_class).to respond_to(:play_no)
  end
  it "can play error" do
    expect(described_class).to respond_to(:play_error)
  end
end
