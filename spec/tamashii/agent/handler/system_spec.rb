require 'spec_helper'
require 'tamashii/agent/master'
require 'tamashii/agent/networking'

RSpec.describe Tamashii::Agent::Handler::System do

  let(:type) { Tamashii::Type::REBOOT } 
  let(:master) { instance_double(Tamashii::Agent::Master) }
  let(:networking) { instance_double(Tamashii::Agent::Networking) }
  let(:env) { {master: master, networking: networking} }
  let(:data) { type.to_s }

  subject {
    described_class.new(type, env)
  }

  describe "#resolve" do
    it "sends a Event::SYSTEM_COMMAND to master" do
      expect(master).to receive(:send_event).with(Tamashii::Agent::Event.new(Tamashii::Agent::Event::SYSTEM_COMMAND, data))
      subject.resolve(data)
    end
  end
end
