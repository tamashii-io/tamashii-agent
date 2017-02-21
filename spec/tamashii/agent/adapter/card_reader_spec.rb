require 'spec_helper'

require 'tamashii/agent/device/fake_card_reader'

RSpec.describe Tamashii::Agent::Adapter::CardReader do
  describe ".real_class" do
    it "returns MFRC522" do
      expect(described_class.real_class).to be MFRC522
    end
  end
  
  describe ".fake_class" do
    it "returns Device::FakeCardReader" do
      expect(described_class.fake_class).to be Tamashii::Agent::Device::FakeCardReader
    end
  end
end
