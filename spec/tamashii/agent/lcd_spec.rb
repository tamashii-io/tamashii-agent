require 'spec_helper'

RSpec.describe Tamashii::Agent::LCD do
  
  let(:ivar_lcd) { subject.instance_variable_get(:@lcd) }
  let(:ivar_device_lock) { subject.instance_variable_get(:@device_lock) }
  let(:ivar_idle_text) { subject.instance_variable_get(:@idle_text) }
  let(:idle_text) { "Idle Message" }
  let(:message) { "MESSAGE" }
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
    it "call print message with @idle_text" do
      expect(ivar_lcd).to receive(:print_message).with(ivar_idle_text)
      subject.print_idle
    end
  end
  
  describe "#clear_screen" do
    it "call print message with empty string" do
      expect(ivar_lcd).to receive(:print_message).with("")
      subject.clear_screen
    end
  end

  describe "#set_idle_text" do

  end
  
  describe "#print_message_with_lock" do
    it "does not allow lcd to be called without using mutex" do
      expect(ivar_device_lock).to receive(:synchronize).and_return(nil)
      expect(ivar_lcd).not_to receive(:print_message)
      subject.print_message_with_lock(message)
    end

    it "expect lcd.print_message to be called when lock is used" do
      expect(ivar_device_lock).to receive(:synchronize).and_yield
      expect(ivar_lcd).to receive(:print_message)
      subject.print_message_with_lock(message)
    end
  end

  describe "#set_idle_text" do
    context "with TIME hint" do
      let(:idle_text) { "Idle message #{Tamashii::AgentHint::TIME}" }
      it "setup auto timer" do
        expect(subject).to receive(:setup_idle_text_auto_update)
        subject.set_idle_text(idle_text)
      end
    end

    context "without TIME hint" do
      let(:idle_text) { "Idle message" }
      it "setup text immediately" do
        expect(subject).to receive(:compute_idle_text)
        subject.set_idle_text(idle_text)
      end
    end
  end


  describe "#compute_idle_text" do
    let(:ivar_idle_text_raw) { subject.instance_variable_get(:@idle_text_raw) }
    context "with TIME hit" do
      let(:idle_text) { "Idle message #{Tamashii::AgentHint::TIME}" }
      before do
        Timecop.freeze(Time.local(2017))
        # mock auto update to immediate run
        allow(subject).to receive(:setup_idle_text_auto_update) do
          subject.compute_idle_text
        end
      end

      after do
        Timecop.return
      end
      it "replace the TIME info with current time" do
        time = Time.now.localtime(Tamashii::Agent::Config.localtime).strftime("%m/%d(%a) %H:%M")
        subject.set_idle_text(idle_text)
        expect(ivar_idle_text).to eq idle_text.gsub(Tamashii::AgentHint::TIME, time)
        subject.compute_idle_text
      end
    end

    context "without TIME hint" do
      let(:idle_text) { "Idle message" }
      it "copy the text only" do
        subject.set_idle_text(idle_text)
        subject.compute_idle_text
        expect(ivar_idle_text).to eq idle_text
      end
    end
  end
end
