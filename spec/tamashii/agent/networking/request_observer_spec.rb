require 'spec_helper'
require 'tamashii/agent/networking'

RSpec.describe Tamashii::Agent::Networking::RequestObserver do
  let(:networking) { instance_double(Tamashii::Agent::Networking) }
  let(:id) { "request_id" }
  let(:req_ev_type) { Tamashii::Type::RFID_NUMBER }
  let(:req_ev_body) { "req body" }
  let(:res_ev_data) { {ev_type: res_ev_type, ev_body: res_ev_body} }
  let(:res_reason) { RuntimeError.new }
  let(:future) { instance_double(Concurrent::Future) }
 
  let(:update_time) { Time.now }

  subject {
    described_class.new(networking, id, req_ev_type, req_ev_body, future)
  }

  describe "#update" do
    context "when the future is fulfilled" do
      before do
        expect(future).to receive(:fulfilled?).and_return true
      end

      context "when the type is handled" do
        let(:res_ev_type) { Tamashii::Type::RFID_RESPONSE_JSON }
        let(:res_ev_body) { "{}" }
        it "let the networking handle the card_result" do
          expect(networking).to receive(:handle_card_result)
          subject.update(update_time, res_ev_data, res_reason)
        end
      end

      context "when the type is not handled" do
        let(:res_ev_type) { Tamashii::Type::RFID_NUMBER } # client-only event type
        let(:res_ev_body) { "abc123" }
        it "do not let the networking handle the card_result" do
          expect(networking).not_to receive(:handle_card_result)
          subject.update(update_time, res_ev_data, res_reason)
        end
      end
    end

    context "when the future is not fulfilled" do
      let(:res_ev_type) { nil }
      let(:res_ev_body) { nil }

      before do
        expect(future).to receive(:fulfilled?).and_return false
      end

      it "timeouts the request" do
        expect(networking).to receive(:on_request_timeout).with(req_ev_type, req_ev_body)
        subject.update(update_time, res_ev_data, res_reason)
      end
    end
  end


end
