require 'spec_helper'


class Tamashii::Agent::DummyClass
  include Tamashii::Agent::Common::Loggable
end
RSpec.describe Tamashii::Agent::Common::Loggable do

  let(:progname)  { "DummyClass" }

  describe "when it is mixed into a class" do
    subject { Tamashii::Agent::DummyClass.new }
    
    it "can get a logger with progname" do
      expect(subject.logger).to be_a Tamashii::Logger
      expect(subject.logger.progname).to eq progname
    end

    it "can generate the program name" do
      expect(subject.progname).to eq progname
    end
    
  end
end
