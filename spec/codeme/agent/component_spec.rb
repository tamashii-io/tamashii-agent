require 'spec_helper'

RSpec.describe Codeme::Agent::Component do
 
  let(:ev_type) { described_class::EVENT_BEEP }
  let(:ev_body) { "test body" }
  let(:dumped_ev) { [ev_type, ev_body.bytesize].pack("Cn") + ev_body }

  describe '#send_event' do
    it "write a event data into pipe, that can be read" do
      pipe_r = subject.instance_variable_get(:@pipe_r)
      subject.send_event(ev_type, ev_body)
      expect(pipe_r.read(dumped_ev.bytesize)).to eq dumped_ev
    end
  end

  describe '#receive_event' do
    it "reads a event in pipe and call #process_event" do
      pipe_w = subject.instance_variable_get(:@pipe_w)
      pipe_w.write dumped_ev
      expect(subject).to receive(:process_event).with(ev_type, ev_body)
      subject.receive_event
    end
  end

  describe "#run and #stop" do
    it "create the worker thread, than stop" do
      expect(subject.instance_variable_get(:@thr)).to be nil
      subject.run
      expect(subject.instance_variable_get(:@thr)).to be_a Thread
      subject.stop
      expect(subject.instance_variable_get(:@thr)).to be nil
    end
  end

  describe "#create_selector" do
    it "create a NIO::Selector object" do
      subject.create_selector
      expect(subject.instance_variable_get(:@selector)).to be_a NIO::Selector
    end
  end
end
