require 'spec_helper'

require 'tamashii/agent/device/pi_buzzer'
require 'tamashii/agent/device/fake_buzzer'

RSpec.describe Tamashii::Agent::Adapter::Buzzer do
  describe ".real_class" do
    it "returns Device::PIBuzzer" do
      expect(described_class.real_class).to be Tamashii::Agent::Device::PIBuzzer
    end
  end
  
  describe ".fake_class" do
    it "returns Device::FakeBuzzer" do
      expect(described_class.fake_class).to be Tamashii::Agent::Device::FakeBuzzer
    end
  end
end
