require 'spec_helper'

RSpec.describe Tamashii::Agent::Connection do


  let(:master) {
    obj = double()
    allow(obj).to receive(:send_event)
    allow(obj).to receive(:host).and_return("manager.dev")
    allow(obj).to receive(:port).and_return(3000)
    obj
  }

  let!(:id) { rand(256) }
  let!(:ev_type) { rand(256) }
  let!(:req_ev_type) { ev_type }
  let!(:res_ev_type) { ev_type }
  let(:ev_body) { {auth: true}.to_json }
  let(:wrapped_ev_body) { {id: id, ev_body: ev_body}.to_json }
  let(:wrapped_ev_body_response) { {id: id, ev_body: '{"auth":true}'}.to_json }

  let(:agent_ev_type) { Tamashii::Agent::Event::CARD_DATA }
  let(:tamashii_ev_type) { Tamashii::Type::RFID_NUMBER }

  let(:pkt_tag) { 2 }
  let(:auth_tag) { 2 }
  let(:pkt_type) { 10 }
  let(:pkt_body) { wrapped_ev_body }
  let(:packet) { Tamashii::Packet.new(pkt_type, pkt_tag, pkt_body) }

  let(:future_ivar_pool) { subject.instance_variable_get(:@future_ivar_pool) }

  let!(:client_instance) do
    client = double("ws client")
    allow(client).to receive(:on)
    allow(client).to receive(:close)
    allow(client).to receive(:transmit)
    client
  end

  subject do 
    # mock ws client
    allow(Tamashii::Client::Base).to receive(:new).and_return(client_instance)
    described_class.new(master)
  end

  context "when connection is established and auth is ready" do
    before(:each) do 
      allow(subject).to receive(:ready?).and_return(true)
      allow(subject).to receive(:auth_pending?).and_return(false)

      subject.instance_variable_set(:@tag , auth_tag)
    end

    shared_examples "process packet and resolve that packet" do
      it "call the Resolver.resolve to resolve the packet" do
        expect(Tamashii::Resolver).to receive(:resolve).with(packet)
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
            expect(Tamashii::Resolver).not_to receive(:resolve).with(packet)
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
        expect(master).to receive(:send_event).with(event_with_type_is(Tamashii::Agent::Event::CONNECTION_NOT_READY))
        subject.on_request_timeout(ev_type, ev_body)
      end
    end

    it "sends the dumped packet data to ws client" do
      expect(client_instance).to receive(:transmit).with(Tamashii::Packet.new(ev_type, auth_tag, wrapped_ev_body).dump)
      subject.try_send_request(ev_type, wrapped_ev_body)
    end

    context "with RFID-related event" do
      let(:ev_body) { id }

      describe "#process_event" do
        it "will request to create a new remote request with Type::RFID_NUMBER" do
          expect(subject).to receive(:new_remote_request).with(id, Tamashii::Type::RFID_NUMBER, wrapped_ev_body)
          subject.process_event(Tamashii::Agent::Event.new(agent_ev_type, ev_body))
        end
      end

      describe "#new_remote_request" do
        context "request is not duplicate" do
          it "will create a new async request" do
            expect(future_ivar_pool[id]).to be_nil
            expect(subject).to receive(:create_request_async).with(id, tamashii_ev_type, wrapped_ev_body)
            subject.new_remote_request(id, tamashii_ev_type, wrapped_ev_body)
          end
        end

        context "request is duplicate" do
          before do
            future_ivar_pool[id] = Concurrent::IVar.new
          end
          it "will not create a new async request" do
            expect(future_ivar_pool[id]).not_to be_nil
            expect(subject).not_to receive(:create_request_async).with(id, tamashii_ev_type, wrapped_ev_body)
            subject.new_remote_request(id, tamashii_ev_type, wrapped_ev_body)
          end
        end
      end

      describe "#create_request_async" do
        before do
          expect(subject).to receive(:create_request_scheduler_task).with(any_args)
        end

        context "when it is fulfilled" do
          let(:res_ev_type) { Tamashii::Type::RFID_RESPONSE_JSON }
          before do
            allow(Tamashii::Agent::Config).to receive(:connection_timeout).and_return(999)
          end
          it "will call #handle_card_result" do
            expect(subject).to receive(:handle_card_result)
            subject.create_request_async(id, tamashii_ev_type, wrapped_ev_body)
            # Wait for IVar to be place in pool
            while(!future_ivar_pool[id])
              sleep 0.1
            end
            subject.handle_remote_response(res_ev_type, wrapped_ev_body_response)
            # Wait for future to continue
            sleep 0.5
          end
        end
  
        context "when it timeout" do
          before do
            allow(Tamashii::Agent::Config).to receive(:connection_timeout).and_return(0)
          end
          it "will call #on_request_timeout" do 
            expect(subject).to receive(:on_request_timeout).with(tamashii_ev_type, wrapped_ev_body)
            subject.create_request_async(id, tamashii_ev_type, wrapped_ev_body)
            sleep 0.1
          end
        end
      end
    end

    describe "#schedule_task_runner" do
      shared_examples "will schedule again" do
        it do
          expect(subject).to receive(:schedule_next_task)
          start_time = Time.now - 1 # assume the task is schedule in the past 
          subject.schedule_task_runner(id, tamashii_ev_type, wrapped_ev_body, start_time, 0)
        end
      end

      shared_examples "will not schedule again" do
        it do
          expect(subject).not_to receive(:schedule_next_task)
          start_time = Time.now - 1 # assume the task is schedule in the past 
          subject.schedule_task_runner(id, tamashii_ev_type, wrapped_ev_body, start_time, 0)
        end
      end

      before do
        allow(Concurrent::ScheduledTask).to receive(:execute)
      end
      context "when #try_send_request returns true" do
        before do 
          allow(subject).to receive(:try_send_request).and_return(true)
        end
        it_behaves_like "will not schedule again"
      end

      context "when #try_send_request returns false" do
        before do 
          allow(subject).to receive(:try_send_request).and_return(false) 
        end
        context "when we still have time" do
          before do
            allow(Tamashii::Agent::Config).to receive(:connection_timeout).and_return(999)
          end
          it_behaves_like "will schedule again"
        end

        context "when we are run out of time" do
          before do
            allow(Tamashii::Agent::Config).to receive(:connection_timeout).and_return(0)
          end
          it_behaves_like "will not schedule again"
        end
      end
    end

    shared_examples "handle system packet" do
      it "passes data to the System handler" do
        expect_any_instance_of(Tamashii::Agent::Handler::System).to receive(:resolve)
        subject.process_packet(packet)
      end
    end

    context "with async system event: REBOOT" do
      let(:pkt_type) { Tamashii::Type::REBOOT }
      it_behaves_like "handle system packet"
    end

    context "with async system event: POWEROFF" do
      let(:pkt_type) { Tamashii::Type::POWEROFF }
      it_behaves_like "handle system packet"
    end


  end

  shared_examples "it will not start data process" do
    it "will not send the packet request" do
      expect(client_instance).not_to receive(:transmit)
      expect(subject.try_send_request(ev_type, wrapped_ev_body)).to be false
    end
  end

  context "when connected but auth is not established" do
    before do 
      allow(subject).to receive(:ready?).and_return(false)
      allow(subject).to receive(:auth_pending?).and_return(true)
    end

    it_behaves_like "it will not start data process"

    context "when packet is broadcasting" do
      let(:pkt_tag) { 0 }
      it "will not resolve it" do
        expect(Tamashii::Resolver).not_to receive(:resolve) 
        subject.process_packet(packet)
      end
    end

    context "when the auth success" do
      let(:pkt_type) { Tamashii::Type::AUTH_RESPONSE }
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
    end
    it_behaves_like "it will not start data process"
  end

end
