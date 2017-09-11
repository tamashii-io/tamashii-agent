require 'spec_helper'

module Tamashii
  module Agent
    class DummyComponent < Component
    end
  end
end

RSpec.describe Tamashii::Agent::Master do


  let(:serv_host) { "manager.dev" }
  let(:serv_port) { 3000 }
  let(:serial_number) { "Test" }

  let(:ev_type) { 1 }
  let(:ev_body) { "ABC" }
  let(:event) { Tamashii::Agent::Event.new(ev_type, ev_body) }

  let!(:component_instance) do
    obj = double()
    allow(obj).to receive(:run)
    allow(obj).to receive(:stop)
    allow(obj).to receive(:send_event)
    obj
  end

  let(:dummy_instance_double) {instance_double(Tamashii::Agent::DummyComponent)  }

  def ivar_components 
    subject.instance_variable_get(:@components)
  end

  let(:component1_param) {
      { class_name: 'DummyComponent', options: { type: "1"}, block: proc {}  }
  }
  let(:component2_param) {
      { class_name: 'DummyComponent', options: { type: "2"}, block: proc {}  }
  }
  let(:components) {
    {
      name1: component1_param,
      name2: component2_param
    }
  }

  before do
    expect(Tamashii::Agent::Config).to receive(:components).and_return(components)
  end

  shared_examples "broadcast to components" do |arg_event|
    it "let all component receive same events" do
      expect(dummy_instance_double).to have_received(:send_event).with(arg_event).exactly(ivar_components.size).times
    end
  end

  describe "#initialize" do
    before do 
      allow_any_instance_of(described_class).to receive(:get_serial_number).and_return(serial_number)
    end

    it 'creates all components described in config' do
      expect_any_instance_of(described_class).to receive(:create_component).with(:name1, component1_param)
      expect_any_instance_of(described_class).to receive(:create_component).with(:name2, component2_param)
      subject
    end

    it 'should gather its serial number' do
      expect(subject.serial_number).to eq serial_number
    end
  end

  describe "#create_component" do
    let(:component_name) { :name }
    let(:component_class) { 'DummyComponent' }
    let(:component_params) { {class_name: component_class, options: {}  }}
    let(:component_instance) { instance_double(Tamashii::Agent::DummyComponent) }
    before do
      allow(Tamashii::Agent::DummyComponent).to receive(:new).and_return(component_instance)
      allow(component_instance).to receive(:run)
    end
    it "runs the component and added it into components" do
      subject.create_component(component_name, component_params)
      expect(ivar_components[component_name]).to be component_instance
      expect(component_instance).to have_received(:run).exactly(3).times
    end
  end

  describe "#process event" do
    let(:master_only_events) { [Tamashii::Agent::Event::SYSTEM_COMMAND] }
    context "when the message should handle by master" do
      it "does not pass this event to any compoments" do
        expect(component_instance).not_to receive(:send_event)
        expect(subject).not_to receive(:broadcast_event).with(Tamashii::Agent::Event.new(ev_type, ev_body))
        master_only_events.each do |ev_type|
          subject.process_event(Tamashii::Agent::Event.new(ev_type, ev_body))
        end
      end
    end

    context "when the connection is not ready" do
      before do
        allow(Tamashii::Agent::DummyComponent).to receive(:new).and_return(dummy_instance_double)
        allow(dummy_instance_double).to receive(:run)
        allow(dummy_instance_double).to receive(:send_event)
        subject.process_event(Tamashii::Agent::Event.new(Tamashii::Agent::Event::CONNECTION_NOT_READY, "ABC"))
      end
      it_behaves_like "broadcast to components", Tamashii::Agent::Event.new(Tamashii::Agent::Event::BEEP, "error")
    end

    context "when the message is not recognized" do
      let(:component_instance) { spy('component') }
      before do 
        allow(Tamashii::Agent::DummyComponent).to receive(:new).and_return(dummy_instance_double)
        allow(dummy_instance_double).to receive(:run)
        allow(dummy_instance_double).to receive(:send_event)
        subject.process_event(Tamashii::Agent::Event.new(987654321, "ABC"))
      end
      it_behaves_like "broadcast to components", Tamashii::Agent::Event.new(987654321, "ABC")
    end
  end

  describe "#stop" do
    before do
      allow(Tamashii::Agent::DummyComponent).to receive(:new).and_return(dummy_instance_double)
      allow(dummy_instance_double).to receive(:run)
      allow(dummy_instance_double).to receive(:stop)
    end
    it "stops all components" do
      subject.stop
      expect(dummy_instance_double).to have_received(:stop).exactly(ivar_components.size).times
    end
  end
end
