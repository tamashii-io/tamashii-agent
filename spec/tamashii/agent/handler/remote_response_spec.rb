require 'spec_helper'
require 'tamashii/agent/master'
require 'tamashii/agent/networking'

RSpec.describe Tamashii::Agent::Handler::RemoteResponse do

  let(:type) { Tamashii::Type::RFID_RESPONSE_JSON } 
  let(:master) { instance_double(Tamashii::Agent::Master) }
  let(:networking) { instance_double(Tamashii::Agent::Networking) }
  let(:env) { {master: master, networking: networking} }
  let(:data) { "remote data" }

  subject {
    described_class.new(type, env)
  }

  describe "#resolve" do
    it "passes the type and data to network" do
      expect(networking).to receive(:handle_remote_response).with(type, data)
      subject.resolve(data)
    end
  end

end
