require 'spec_helper'

require 'codeme/agent/device/pi_buzzer'
require 'codeme/agent/device/fake_buzzer'

RSpec.describe Codeme::Agent::Adapter::Buzzer do
  describe ".real_class" do
    it "returns Device::PIBuzzer" do
      expect(described_class.real_class).to be Codeme::Agent::Device::PIBuzzer
    end
  end
  
  describe ".fake_class" do
    it "returns Device::FakeBuzzer" do
      expect(described_class.fake_class).to be Codeme::Agent::Device::FakeBuzzer
    end
  end
end
