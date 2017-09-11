require 'spec_helper'
require 'tamashii/agent/master'
require 'tamashii/agent/device/device_base'

RSpec.describe Tamashii::Agent::Component do
 
  let(:ev_type) { Tamashii::Agent::Event::BEEP }
  let(:ev_body) { "test body" }
  let(:event) { Tamashii::Agent::Event.new(ev_type, ev_body) }
  let(:event_queue) { subject.instance_variable_get(:@event_queue) }

  let(:master) { instance_double(Tamashii::Agent::Master) }
  let(:name) { :component }
  let(:options) { {} }

  subject { described_class.new(name, master, options) }

  describe '#send_event' do
    it "can be called with a event, which can be checked right after" do
      subject.send_event(event)
      expect(subject.check_new_event).to eq event
    end
  end

  describe '#check_new_event' do
    context "event queue is empty" do
      it "returns nil when non_block=true" do
        expect(event_queue.size).to be 0
        expect(subject.check_new_event(true)).to be_nil
      end
    end

    context "event queue is not empty" do
      it "pulls a existing event out from event queue" do
        event_queue.push(event)
        size_before = event_queue.size
        poped_event = subject.check_new_event
        size_after = event_queue.size
        expect(poped_event).to eq event
        expect(size_after).to eq (size_before - 1)
      end
    end
  end

  describe '#handle_new_event' do
    it "calls #process_event if the event exists" do
      event_queue.push(event)
      expect(subject).to receive(:process_event).with(event).exactly(1).times
      subject.handle_new_event
    end

    it "does not call #process_event when there is no event when run in non block mode" do
      expect(event_queue.size).to be 0
      expect(subject).not_to receive(:process_event)
      subject.handle_new_event(true)
    end
  end

  describe "#worker_loop" do
    before do
      allow(subject).to receive(:handle_new_event).and_return(nil)
    end
    it "terminates when no longer able to get new event" do
      expect(event_queue.size).to be 0
      expect(subject).to receive(:handle_new_event).exactly(1).times
      subject.worker_loop
    end
  end

  describe "#run and #stop" do
    it "create the worker thread, than stop" do
      expect(subject.instance_variable_get(:@worker_thr)).to be nil
      subject.run
      expect(subject.instance_variable_get(:@worker_thr)).to be_a Thread
      subject.stop
      expect(subject.instance_variable_get(:@worker_thr)).to be nil
    end
  end

  describe "#restart_current_component_async" do
    it "createa restart event to master using its class as param" do
      expect(master).to receive(:send_event).with(Tamashii::Agent::Event.new(Tamashii::Agent::Event::RESTART_COMPONENT, name))
      subject.restart_current_component_async
    end
  end


  describe "#initialize_device" do
    let(:device_instance) { instance_double(Tamashii::Agent::Device::DeviceBase) }
    let(:default_device_instance) { instance_double(Tamashii::Agent::Device::DeviceBase) }
    let(:device_name) { 'Device' }
    let(:default_device_name) { 'DefaultDevice' }
    before do
      allow(subject).to receive(:load_default_device).and_return(default_device_instance)
      allow(subject).to receive(:default_device_name).and_return default_device_name
    end
    context "when we can successfully get the device instance" do
      before do
        expect(subject).to receive(:get_device_instance).and_return device_instance
      end

      it "returns a device instance" do
        expect(subject.initialize_device).to be device_instance
      end
    end

    context "when get device instance raise error" do
      before do
        expect(subject).to receive(:get_device_instance).and_raise RuntimeError
      end
      it "returns a default device" do
        expect(subject.initialize_device).to be default_device_instance
      end
    end
  end

  describe "#load_default_device" do
    let(:default_device_instance) { instance_double(Tamashii::Agent::Device::DeviceBase) }
    let(:default_device_name) { 'DefaultDevice' }
    before do
      allow(subject).to receive(:get_device_instance).with(default_device_name).and_return(default_device_instance)
      allow(subject).to receive(:default_device_name).and_return default_device_name
    end

    it "returns a default device" do
      expect(subject.load_default_device).to be default_device_instance
      allow(subject).to receive(:default_device_name).and_return default_device_name
    end

  end


end
