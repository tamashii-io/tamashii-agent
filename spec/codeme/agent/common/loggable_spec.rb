require 'spec_helper'


class Codeme::Agent::DummyClass
  include Codeme::Agent::Common::Loggable
end
RSpec.describe Codeme::Agent::Common::Loggable do

  let(:progname)  { "DummyClass" }

  describe "when it is mixed into a class" do
    subject { Codeme::Agent::DummyClass.new }
    
    it "can get a logger with progname" do
      expect(subject.logger).to be_a Codeme::Logger
      expect(subject.logger.progname).to eq progname
    end

    it "can generate the program name" do
      expect(subject.progname).to eq progname
    end
    
  end
end
