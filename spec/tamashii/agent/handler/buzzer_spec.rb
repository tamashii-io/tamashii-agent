require 'spec_helper'
require 'tamashii/agent/master'
require 'tamashii/agent/networking'

RSpec.describe Tamashii::Agent::Handler::Buzzer do

  let(:type) { Tamashii::Type::BUZZER_SOUND } 
  let(:master) { instance_double(Tamashii::Agent::Master) }
  let(:networking) { instance_double(Tamashii::Agent::Networking) }
  let(:env) { {master: master, networking: networking} }
  let(:data) { "ok" }

  subject {
    described_class.new(type, env)
  }

  describe "#resolve" do
    it "sends a Event::BEEP to master" do
      expect(master).to receive(:send_event).with(Tamashii::Agent::Event.new(Tamashii::Agent::Event::BEEP, data))
      subject.resolve(data)
    end
  end
end
