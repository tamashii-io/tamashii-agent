require 'spec_helper'
require 'tamashii/agent/master'

RSpec.describe Tamashii::Agent::CardReader do
  
  let!(:uid) { Array.new(4){rand(256)} }
  let!(:uid_string) { uid.join("-") }
  let(:ivar_reader) { subject.instance_variable_get(:@reader) }
  let(:ivar_selector) { subject.instance_variable_get(:@selector) }
  let(:master) { instance_double(Tamashii::Agent::Master) }
  let(:name) { :card_reader }
  let(:device_class_name) { 'Dummy' }
  let(:options) { {device: device_class_name} }

  subject { described_class.new(name, master, options) }

  describe "#initialize_device" do
    it "create a device from options" do
      expect(ivar_reader).to be_a Tamashii::Agent::Device::CardReader::Dummy
    end
  end

  describe "#handle_card" do
    context "when Reader#poll_uid return nil, means there is no card available" do
      before do
        expect(ivar_reader).to receive(:poll_uid).and_return(nil)
      end
      it "neither set the error timer nor call the process_uid, returns false" do
        expect(subject).not_to receive(:set_error_timer) 
        expect(subject).not_to receive(:process_uid)
        expect(subject.handle_card).to be false
      end
    end

    context "when Reader#poll_uid return :error, means there is a reader error" do
      before do
        expect(ivar_reader).to receive(:poll_uid).and_return(:error)
      end
      it "set the error timer but not call the process_uid, returns false" do
        expect(subject).to receive(:set_error_timer) 
        expect(subject).not_to receive(:process_uid)
        expect(subject.handle_card).to be false
      end
    end

    context "when Reader#poll_uid return a card uid" do
      before do
        expect(ivar_reader).to receive(:poll_uid).and_return(uid)
      end
      it "resets the error timer, calls the process_uid and returns true" do
        expect(subject).to receive(:reset_error_timer) 
        expect(subject).to receive(:process_uid).with(uid)
        expect(subject.handle_card).to be true
      end
    end
  end

  describe "#process_uid" do
    it "sends the uid as card event to master" do
      expect(master).to receive(:send_event).with(Tamashii::Agent::Event.new(Tamashii::Agent::Event::CARD_DATA, uid_string))
      subject.process_uid(uid)
    end
  end

  describe "#clean_up" do
    it "calls the Reader#shutdown" do
      expect(ivar_reader).to receive(:shutdown)
      subject.clean_up
    end
  end
end
