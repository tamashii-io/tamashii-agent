require 'spec_helper'

RSpec.describe Tamashii::Agent::LCD do
  
  let(:ivar_lcd) { subject.instance_variable_get(:@lcd) }
  let(:ivar_idle_message) { subject.instance_variable_get(:@idle_message) }
  let(:idle_message) { "Idle Message" }
  let!(:master) do 
    obj = double()
    allow(obj).to receive(:send_event)
    obj
  end

  subject { described_class.new(master) }

  describe "#initialize" do
    it "creates a reader by calling Adapter::LCD.object" do
      expect(Tamashii::Agent::Adapter::LCD).to receive(:object).and_call_original
      subject
    end

    context "when device creation has error" do
      before do
        allow(Tamashii::Agent::Adapter::LCD).to receive(:object).and_throw(RuntimeError.new("error"))
      end
      it "create Adapter::LCD.fake_class as @lcd" do
        expect(ivar_lcd).to be_a Tamashii::Agent::Adapter::LCD.fake_class
        subject
      end
    end
  end

  describe "#print_idle" do
    it "call print message with @idle_messsage" do
      expect(ivar_lcd).to receive(:print_message).with(ivar_idle_message)
      subject.print_idle
    end
  end
  
  describe "#clear_screen" do
    it "call print message with empty string" do
      expect(ivar_lcd).to receive(:print_message).with("")
      subject.clear_screen
    end
  end
end
