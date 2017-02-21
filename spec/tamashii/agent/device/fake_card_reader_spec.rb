require 'spec_helper'

RSpec.describe Tamashii::Agent::Device::FakeCardReader do
  it "receives picc_request and return true or false" do
    expect([true, false]).to be_include subject.picc_request
  end
  it "receives picc_halt" do
    expect(subject).to respond_to(:picc_halt)
  end
  it "receives picc_select and return a card number array with state string" do
    card_number_array, state = subject.picc_select
    expect(state).to be_a String
    4.times do |i|
      expect(card_number_array[i].to_i).to be_a Integer
    end
  end
end
