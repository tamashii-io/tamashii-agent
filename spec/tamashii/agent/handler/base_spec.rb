require 'spec_helper'
require 'tamashii/agent/master'
require 'tamashii/agent/networking'

RSpec.describe Tamashii::Agent::Handler::Base do

  let(:type) { Tamashii::Type::POWEROFF } 
  let(:master) { instance_double(Tamashii::Agent::Master) }
  let(:networking) { instance_double(Tamashii::Agent::Networking) }
  let(:env) { {master: master, networking: networking} }

  subject {
    described_class.new(type, env)
  }

  describe "#initialize" do
    it "save the master and networking as its instance variable" do
      expect(subject.instance_variable_get(:@master)).to be master
      expect(subject.instance_variable_get(:@networking)).to be networking
       
    end
  end
end
