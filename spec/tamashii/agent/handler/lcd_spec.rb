require 'spec_helper'
require 'tamashii/agent/master'
require 'tamashii/agent/networking'

RSpec.describe Tamashii::Agent::Handler::Lcd do

  let(:master) { instance_double(Tamashii::Agent::Master) }
  let(:networking) { instance_double(Tamashii::Agent::Networking) }
  let(:env) { {master: master, networking: networking} }
  let(:data) { "ok" }

  subject {
    described_class.new(type, env)
  }

  describe "#resolve" do
    context "when event type is Type::LCD_MESSAGE" do
      let(:type) { Tamashii::Type::LCD_MESSAGE} 

      it "sends a Event::LCD_MESSAGE to master" do
        expect(master).to receive(:send_event).with(Tamashii::Agent::Event.new(Tamashii::Agent::Event::LCD_MESSAGE, data))
        subject.resolve(data)
      end
    end

    context "when event type is Type::LCD_SET_IDLE_TEXT" do
      let(:type) { Tamashii::Type::LCD_SET_IDLE_TEXT} 

      it "sends a Event::LCD_SET_IDLE_TEXT to master" do
        expect(master).to receive(:send_event).with(Tamashii::Agent::Event.new(Tamashii::Agent::Event::LCD_SET_IDLE_TEXT, data))
        subject.resolve(data)
      end
    end
  end
end
