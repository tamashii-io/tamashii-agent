require 'spec_helper'

RSpec.describe Codeme::Agent::Device::PIBuzzer do
  
  before do 
    fake_pwm = double()
    allow(fake_pwm).to receive(:on).with(no_args)
    allow(fake_pwm).to receive(:off).with(no_args)
    allow(fake_pwm).to receive(:value=) do |value|
      expect(value).to be_a Numeric
    end
    allow(PiPiper::Pwm).to receive(:new).and_return(fake_pwm)
  end
  
  it "can stop" do
    expect(subject).to respond_to(:stop)
  end
  it "can play ok" do
    expect(subject).to respond_to(:play_ok)
  end
  it "can play no" do
    expect(subject).to respond_to(:play_no)
  end
  it "can play error" do
    expect(subject).to respond_to(:play_error)
  end
end
