require 'spec_helper'

RSpec.describe Tamashii::Agent::Event do
  let(:ev_type) { Tamashii::Agent::Event::BEEP }
  let(:ev_body) { "ev_body" }
  
  describe "#==" do
    it "only test the equality for type and body" do
      ev1 = described_class.new(ev_type, ev_body)
      ev2 = described_class.new(ev_type, ev_body)
      expect(ev1).to eq ev2      
    end
  end
  
end
