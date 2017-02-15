require 'spec_helper'

require 'tamashi/agent/device/pi_buzzer'
require 'tamashi/agent/device/fake_buzzer'

RSpec.describe Tamashi::Agent::Adapter::Buzzer do
  describe ".real_class" do
    it "returns Device::PIBuzzer" do
      expect(described_class.real_class).to be Tamashi::Agent::Device::PIBuzzer
    end
  end
  
  describe ".fake_class" do
    it "returns Device::FakeBuzzer" do
      expect(described_class.fake_class).to be Tamashi::Agent::Device::FakeBuzzer
    end
  end
end
