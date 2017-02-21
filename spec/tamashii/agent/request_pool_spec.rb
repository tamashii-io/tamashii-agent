require 'spec_helper'

RSpec.describe Tamashii::Agent::RequestPool do

  let(:sym) { :test_sym }
  let(:handler) { lambda { |*args| args } }
  let!(:dummy_args) { Array.new(4) { rand(256) } }
  let(:ivar_pool) { subject.instance_variable_get(:@pool) }

  let!(:id) { rand(256) }
  let!(:ev_type) { rand(256) }
  let(:ev_body) { "Test Body" }
  let(:wrapped_body) { {id: id, ev_body: ev_body}.to_json }
  let(:request) { described_class::Request.new(ev_type, ev_body, id) }
  let(:response) { described_class::Response.new(ev_type, wrapped_body) }

  let(:timedout) { 3 }

  let(:req_timestamp) { Time.now }
  let(:req_timedout) { timedout }
  let(:req_data) { {req: request, timestamp: req_timestamp, timedout: req_timedout } }


  describe "#set_handler" do
    it "can set a handler" do
      expect(subject.handle?(sym)).to be false
      subject.set_handler(sym, handler)
      expect(subject.handle?(sym)).to be true
    end
  end


  describe "#handle?" do
    it "can test if a handler is exists in its pool" do
      handler_pool = subject.instance_variable_get(:@handlers)
      expect(subject.handle?(sym)).to eq handler_pool.has_key?(sym)
      subject.set_handler(sym, handler)
      expect(subject.handle?(sym)).to eq handler_pool.has_key?(sym)
    end
  end

  describe "#call_handler" do
    it "can call the handler if the handler exists" do
      subject.set_handler(sym, handler)
      expect(subject.call_handler(sym, *dummy_args)).to eq dummy_args
    end
    it "does not call the handler if not handled" do
      expect(subject.call_handler(sym, *dummy_args)).not_to eq dummy_args
    end
  end


  describe "#add_request" do
    it "can add request to the pool, and try to send the request" do
      expect(subject).to receive(:try_send_request)
      subject.add_request(request, timedout)
      expect(req_data[:req]).to be request
      expect(req_data[:timestamp]).to be_a Time
      expect(req_data[:timedout]).to be timedout
    end
  end

  describe "#add_response" do
    it "call the handler request_meet if the request exists" do
      subject.add_request(request)
      expect(subject).to receive(:call_handler).with(:request_meet, request, response)
      subject.add_response(response)
    end

    it "discard the response if the request not exists" do
      expect(subject).not_to receive(:call_handler)
      subject.add_response(response)
    end
  end

  describe "#update" do
    it "calls #process_pending and #check_timedout" do
      expect(subject).to receive(:process_pending)
      expect(subject).to receive(:check_timedout)
      subject.update
    end
  end

  describe "#check_timedout" do
    context "when the request is expired" do
      let(:req_timestamp){ Time.now - req_timedout - 1  }
      it "will be removed from pool, and call the timedout handler" do
        ivar_pool[id] = req_data
        expect(subject).to receive(:call_handler).with(:request_timedout, request)
        subject.check_timedout
        expect(ivar_pool.has_key?(id)).to be false
      end
    end

    context "when the request is not expired" do
      it "keeps the req_data in the pool" do
        ivar_pool[id] = req_data
        subject.check_timedout
        expect(ivar_pool.has_key?(id)).to be true
      end
    end
  end

  describe "#process_pending" do
    it "calls #try_send_request for un-sent requests" do
      req_sent = described_class::Request.new(ev_type, ev_body, 1)
      req_sent.sent!
      req_pending = described_class::Request.new(ev_type, ev_body, 2)
      
      subject.add_request(req_sent)
      subject.add_request(req_pending)

      expect(subject).to receive(:try_send_request).with(req_pending)
      expect(subject).not_to receive(:try_send_request).with(req_sent)
      subject.process_pending
    end
  end

  describe "#try_send_request" do
    context "when the handler for send is not exists" do
      it "will neither call #call_handler nor Request#sent!" do
        expect(subject.handle?(:send_request)).to be false
        expect(subject).not_to receive(:call_handler)
        expect(request).not_to receive(:sent!)
        subject.try_send_request(request)
      end
    end

    context "when the handler for send is exist" do
      before do
        subject.set_handler(:send_request, handler)
      end
      context "when the handler returns true" do
        it "will call the Request#sent!" do
          expect(subject).to receive(:call_handler).with(:send_request, request).and_return(true)
          expect(request).to receive(:sent!)
          subject.try_send_request(request)
        end
      end

      context "when the handler returns false" do
        it "will not call the Request#sent!" do
          expect(subject).to receive(:call_handler).with(:send_request, request).and_return(false)
          expect(request).not_to receive(:sent!)
          subject.try_send_request(request)
        end
      end
    end
  end
end
