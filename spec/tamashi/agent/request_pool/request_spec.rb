require 'spec_helper'

RSpec.describe Tamashi::Agent::RequestPool::Request do
  let(:id) { rand(256) }
  let(:ev_type) { rand(256) }
  let(:ev_body) { "Test Body" }
  let(:wrapped_body) { {id: id, ev_body: ev_body}.to_json }

  subject{ described_class.new(ev_type, ev_body, id) }

  it "has initial state : PENDING" do
    expect(subject.state).to be described_class::STATE_PENDING
  end

  it "can change the state to sent by #sent!" do
    subject.sent!
    expect(subject.state).to be described_class::STATE_SENT
  end

  it "can check whether itself is sent?" do
    expect(subject.sent?).to be false
    subject.sent!
    expect(subject.sent?).to be true
  end

  it "can wrap the ev_body" do
    expect(subject.wrap_body).to eq wrapped_body
  end

end
