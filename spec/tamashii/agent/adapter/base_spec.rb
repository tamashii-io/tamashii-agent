require 'spec_helper'


RSpec.describe Tamashii::Agent::Adapter::Base do

  describe ".object" do
    let(:args) { [1,2,3,4] }
    let(:block) { proc { puts "Hello" } }
    it "call the current_class.new with same argment" do
      dummy_class = double()
      expect(dummy_class).to receive(:new) { |*given_args, &given_block| [given_args,given_block] }
      expect(described_class).to receive(:current_class).and_return(dummy_class)
      expect(described_class.object(*args, &block)).to eq [args, block]
    end
  end

  describe ".current_class" do
    before do
      allow(described_class).to receive(:real_class)
      allow(described_class).to receive(:fake_class)
    end
    context "when env is test" do
      before do
        allow(Tamashii::Agent::Config).to receive(:env).and_return("test")
      end
      it "returns the fake_class" do
        expect(described_class).to receive(:fake_class)
        described_class.current_class
      end
    end

    context "when env is not test" do
      before do
        allow(Tamashii::Agent::Config).to receive(:env).and_return("production")
      end
      it "returns the real_class" do
        expect(described_class).to receive(:real_class)
        described_class.current_class
      end
    end
  end

  describe ".fake_class and .real_class" do
    it "both raise NotImplenentedError" do
      expect{described_class.fake_class}.to raise_error(NotImplementedError)
      expect{described_class.real_class}.to raise_error(NotImplementedError)
    end
  end
end
