require 'spec_helper'

RSpec.describe Tamashi::Agent::CardReader do
  
  let(:ivar_reader) { subject.instance_variable_get(:@reader) }
  let(:ivar_selector) { subject.instance_variable_get(:@selector) }
  let!(:master) do 
    obj = double()
    allow(obj).to receive(:send_event)
    obj
  end

  subject { described_class.new(master) }

  describe "#initialize" do
    it "creates a reader by calling Adapter::CardReader.object" do
      expect(Tamashi::Agent::Adapter::CardReader).to receive(:object)
      subject
    end
  end
  
  describe "#handle_io" do
    it "calls the select of ivar_selector" do
      subject.create_selector
      expect(ivar_selector).to receive(:select)
      subject.handle_io
    end
  end

  describe "#handle_card" do
    context "when Reader#picc_request return false" do
      before do
        expect(ivar_reader).to receive(:picc_request).and_return(false)
      end
      it "does not call Reader#pic_select, Reader#picc_halt, #process_uid" do
        expect(ivar_reader).not_to receive(:picc_select)
        expect(ivar_reader).not_to receive(:picc_halt)
        expect(subject).not_to receive(:process_uid)
        subject.handle_card
      end
    end

    context "when Reader#picc_request return true" do
      before do
        expect(ivar_reader).to receive(:picc_request).and_return(true)
      end
      it "calls the Reader#pic_select and Reader#picc_halt, also #process_uid" do
        expect(ivar_reader).to receive(:picc_select).and_return([Array.new(4){rand(256)},"sak"])
        expect(ivar_reader).to receive(:picc_halt)
        expect(subject).to receive(:process_uid)
        subject.handle_card
      end
    end
  end

  describe "#process_uid" do
    let(:uid) { Array.new(4){rand(256)}.join("-") }
    it "sends the uid as card event to master" do
      expect(master).to receive(:send_event).with(Tamashi::Agent::EVENT_CARD_DATA, uid)
      subject.process_uid(uid)
    end
  end
end
