require 'spec_helper'
require 'tamashii/agent/device/buzzer/dummy'
require 'tamashii/agent/master'

RSpec.describe Tamashii::Agent::Buzzer do
  
  let(:ivar_buzzer) { subject.instance_variable_get(:@buzzer) }

  let(:master) { instance_double(Tamashii::Agent::Master) }
  let(:name) { :buzzer }
  let(:device_class_name) { 'Dummy' }
  let(:options) { {device: device_class_name} }

  subject { described_class.new(name, master, options) }

  describe "#initialize_device" do
    it "create a device from options" do
      expect(ivar_buzzer).to be_a Tamashii::Agent::Device::Buzzer::Dummy
    end
  end

  shared_examples "buzzer will not react" do
    it "will not call any buzzer methods" do
      expect(ivar_buzzer).not_to receive(:play_ok)
      expect(ivar_buzzer).not_to receive(:play_no)
      expect(ivar_buzzer).not_to receive(:play_error)
      subject.process_event(Tamashii::Agent::Event.new(ev_type, ev_body))
    end
  end

  describe "#default_device_name" do
    it "equals to Dummy device" do
      expect(subject.default_device_name).to eq device_class_name
    end
  end

  describe "#process_event" do
    context "when ev_type is not EVENT_BEEP" do
      let(:ev_type){ Tamashii::Agent::Event::CARD_DATA }
      let(:ev_body) { "other" }
      let(:event) { Tamashii::Agent::Event.new(ev_type, ev_body) }
      it_behaves_like "buzzer will not react"
    end

    context "when ev_type is EVENT_BEEP" do
      let(:ev_type){ Tamashii::Agent::Event::BEEP }
      it "calls Buzzer#play_ok when ev_body is ok" do
        expect(ivar_buzzer).to receive(:play_ok)
        subject.process_event(Tamashii::Agent::Event.new(ev_type, "ok"))
      end

      it "calls Buzzer#play_no when ev_body is no" do
        expect(ivar_buzzer).to receive(:play_no)
        subject.process_event(Tamashii::Agent::Event.new(ev_type, "no"))
      end
      
      it "calls Buzzer#play_error when ev_body is error" do
        expect(ivar_buzzer).to receive(:play_error)
        subject.process_event(Tamashii::Agent::Event.new(ev_type, "error"))
      end

      context "when the ev_body is not corrent" do
        let(:ev_body) { "other" }
        it_behaves_like "buzzer will not react"
      end
    end
  end

  describe "#clean_up" do
    it "calls the Buzzer#shutdown" do
      expect(ivar_buzzer).to receive(:shutdown)
      subject.clean_up
    end
  end
end
