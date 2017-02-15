require 'spec_helper'

RSpec.describe Tamashi::Agent::Connection do

  let(:host) { "manager.dev" }
  let(:port) { 3000 }
  let(:master) {
    obj = double()
    allow(obj).to receive(:send_event)
    obj
  }
  
  let!(:id) { rand(256) }
  let!(:ev_type) { rand(256) }
  let!(:req_ev_type) { ev_type }
  let!(:res_ev_type) { ev_type }
  let(:ev_body) { {auth: true}.to_json }
  let(:wrapped_body) { {id: id, ev_body: ev_body}.to_json }
  let(:request) { Tamashi::Agent::RequestPool::Request.new(req_ev_type, ev_body, id) }
  let(:response) { Tamashi::Agent::RequestPool::Response.new(res_ev_type, wrapped_body) }

  let(:pkt_tag) { 2 }
  let(:auth_tag) { 2 }
  let(:pkt_type) { 10 }
  let(:pkt_body) { wrapped_body }
  let(:packet) { Tamashi::Packet.new(pkt_type, pkt_tag, pkt_body) }

  let(:fake_io) {
    r, w = IO.pipe
    r
  }

  subject { described_class.new(master, host, port) }

  context "when auth and connection is established" do
    let!(:ws_instance) do
        driver = double('ws driver')
        allow(driver).to receive(:on)
        allow(driver).to receive(:start)
        allow(driver).to receive(:parse)
        allow(driver).to receive(:binary)
        driver
    end
    before do 
      
      allow(subject).to receive(:ready?).and_return(true)
      allow(subject).to receive(:auth_pending?).and_return(false)
      allow(subject).to receive(:connecting?).and_return(false)
      # mock ws driver
      allow(WebSocket::Driver).to receive(:client).and_return(ws_instance)

      subject.instance_variable_set(:@io, fake_io)
      subject.create_selector
      subject.start_web_driver
      subject.instance_variable_set(:@tag , auth_tag)

    end

    shared_examples "process packet and resolve that packet" do
      it "call the Resolver.resolve to resolve the packet" do
        expect(Tamashi::Resolver).to receive(:resolve).with(packet)
        subject.process_packet(packet)
      end
    end

    describe "#process_packet" do
      context "with unicast tag" do
        let(:pkt_tag) { 2 }
        context "when match the auth_tag" do
          let(:auth_tag) { 2 }
          it_behaves_like "process packet and resolve that packet"
        end

        context "when mismatch" do
          let(:auth_tag) { 3 }
          it "will not resolve that packet" do
            expect(Tamashi::Resolver).not_to receive(:resolve).with(packet)
            subject.process_packet(packet)
          end
        end
      end

      context "with broadcast tag" do
        let(:pkt_tag) { 0 }
        it_behaves_like "process packet and resolve that packet"
      end
    end

    context "when the request is timedout" do
      it "sends a not ready event to master" do
        expect(master).to receive(:send_event).with(Tamashi::Agent::EVENT_CONNECTION_NOT_READY, any_args)
        subject.handle_request_timedout(request)
      end
    end

    context "when the request is meet" do
      let!(:res_ev_type) { Tamashi::Type::RFID_RESPONSE_JSON }
      it "send a beep event to master" do
        expect(master).to receive(:send_event).with(Tamashi::Agent::EVENT_BEEP, any_args)
        subject.handle_request_meet(request, response)
      end
    end

    it "can send the request to ws driver" do
      expect(ws_instance).to receive((:binary))
      subject.handle_send_request(request)
    end

    context "with RFID-related event" do
      let(:ev_type) { Tamashi::Agent::EVENT_CARD_DATA }
      it "can convert EVENT_CARD_DATA to Request and put into pool" do
        expect(Tamashi::Agent::RequestPool::Request).to receive(:new).with(Tamashi::Type::RFID_NUMBER, ev_body, ev_body).and_return(request)
        subject.process_event(ev_type, ev_body)
      end
    end

    context "with RFID-related data" do
      let(:pkt_type) { Tamashi::Type::RFID_RESPONSE_JSON }
      it "passes data to the RFID handler" do
        expect_any_instance_of(Tamashi::Agent::Handler::RequestPoolResponse).to receive(:resolve)
        subject.process_packet(packet)
      end
    end

    shared_examples "handle system packet" do
      it "passes data to the System handler" do
        expect_any_instance_of(Tamashi::Agent::Handler::System).to receive(:resolve)
        subject.process_packet(packet)
      end
    end

    context "with async system event: REBOOT" do
      let(:pkt_type) { Tamashi::Type::REBOOT }
      it_behaves_like "handle system packet"
    end
    
    context "with async system event: POWEROFF" do
      let(:pkt_type) { Tamashi::Type::POWEROFF }
      it_behaves_like "handle system packet"
    end


  end

  shared_examples "it will not start data process" do
    it "will not send the packet requested by request_pool" do
      expect(subject.handle_send_request(request)).to be false
    end
  end

  context "when connected but auth is not established" do
    before do 
      allow(subject).to receive(:ready?).and_return(false)
      allow(subject).to receive(:auth_pending?).and_return(true)
      allow(subject).to receive(:connecting?).and_return(false)
    end
    
    it_behaves_like "it will not start data process"
    
    context "when packet is broadcasting" do
      let(:pkt_tag) { 0 }
      it "will not resolve it" do
        expect(Tamashi::Resolver).not_to receive(:resolve) 
        subject.process_packet(packet)
      end
    end

    context "when the auth success" do
      let(:pkt_type) { Tamashi::Type::AUTH_RESPONSE }
      let(:pkt_body) { "0" }
      let(:pkt_tag) { "2" }
      it "receive the tag and call the auth_success" do
        expect(subject.instance_variable_get(:@tag)).not_to eq pkt_tag
        expect(subject).to receive(:auth_success)
        subject.process_packet(packet)
        expect(subject.instance_variable_get(:@tag)).to eq pkt_tag
      end
    end
  end

  context "when not connected" do
    before do 
      allow(subject).to receive(:ready?).and_return(false)
      allow(subject).to receive(:auth_pending?).and_return(false)
      allow(subject).to receive(:connecting?).and_return(true)
    end
    it_behaves_like "it will not start data process"
  end

end
