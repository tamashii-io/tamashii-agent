require 'spec_helper'


class Tamashi::Agent::DummyClass
  include Tamashi::Agent::Common::Loggable
end
RSpec.describe Tamashi::Agent::Common::Loggable do

  let(:progname)  { "DummyClass" }

  describe "when it is mixed into a class" do
    subject { Tamashi::Agent::DummyClass.new }
    
    it "can get a logger with progname" do
      expect(subject.logger).to be_a Tamashi::Logger
      expect(subject.logger.progname).to eq progname
    end

    it "can generate the program name" do
      expect(subject.progname).to eq progname
    end
    
  end
end
