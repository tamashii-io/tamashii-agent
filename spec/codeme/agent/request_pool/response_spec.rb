require 'spec_helper'

RSpec.describe Codeme::Agent::RequestPool::Response do
  let(:id) { rand(256) }
  let(:ev_type) { rand(256) }
  let(:ev_body) { "Test Body" }
  let(:wrapped_body) { {id: id, ev_body: ev_body}.to_json }

  subject{ described_class.new(ev_type, wrapped_body) }

  it "stores ev_type and decode the wrapped data into id and ev_body" do
    expect(subject.id).to eq id
    expect(subject.ev_type).to eq ev_type
    expect(subject.ev_body).to eq ev_body
  end
end
