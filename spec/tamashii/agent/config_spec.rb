require 'spec_helper'
require 'securerandom'

RSpec.describe Tamashii::Agent::Config do

  describe ".auth_type" do
    it "can be changed" do
      expect(subject.auth_type).to eq(:none)
      subject.auth_type(:token)
      expect(subject.auth_type).to eq(:token)
    end

    it "cannot change to invalid type" do
      origin_auth_type = subject.auth_type
      subject.auth_type(:invalid)
      expect(subject.auth_type).to eq(origin_auth_type)
    end
  end

  describe ".token" do
    it "can be changed" do
      new_token = SecureRandom.hex(16)
      expect(subject.token).to be_nil
      subject.token = new_token
      expect(subject.token).to eq(new_token)
    end
  end

  describe ".log_file" do
    it "default output to STDOUT" do
      expect(subject.log_file).to eq(STDOUT)
    end

    context "setter will also changes the value in Tamashii::Client" do
      before do
        @old_client_log_file = Tamashii::Client.config.log_file
      end
      after do
        Tamashii::Client.config.log_file = @old_client_log_file
      end
      it "has the same value as agent" do
        path = SecureRandom.hex(16)
        subject.log_file(path)
        expect(Tamashii::Client.config.log_file).to eq(path)
      end
    end
  end

  describe ".log_level" do
    it "default to DEBUG" do
      expect(subject.log_level).to eq(Logger::DEBUG)
    end

    it "can be changed" do
      subject.log_level(Logger::INFO)
      expect(subject.log_level).to eq(Logger::INFO)
    end


    context "setter will also changes the value in Tamashii::Client" do
      before do
        @old_client_log_level = Tamashii::Client.config.log_level
      end
      after do
        Tamashii::Client.config.log_level(@old_client_log_level)
      end
      it "setter will also change the value in Tamashii::Client" do
        subject.log_level(Logger::INFO)
        expect(Tamashii::Client.config.log_level).to eq(Logger::INFO)
      end
    end
  end

  describe ".env" do
    it "default is development" do
      expect(subject.env.development?).to be true
    end

    it "load config from environment variable" do
      expect(ENV).to receive(:[]).with('RACK_ENV').and_return("production")
      expect(subject.env.production?).to be true
    end

    it "can be set by config" do
      subject.env(:production)
      expect(subject.env.production?).to be true
    end

    it "can compare by string" do
      expect(subject.env).to eq("development")
    end

    it "can compare by symbol" do
      expect(subject.env).to eq(:development)
    end
  end

  forward_methods = [:use_ssl, :host, :port, :entry_point]
  describe "forwarded methods: #{forward_methods.join(', ')}" do
    forward_methods.each do |method_name|
      it "forward the client-specific method #{method_name} calls to Tamashii::Client" do
        expect(Tamashii::Client.config).to receive(method_name)
        subject.send(method_name)
      end
    end
  end

  describe "#add_component" do
    let(:new_component_name) { :new_name }
    let(:new_component_class) { 'Component' }
    let(:new_component_option) { {} }
    let(:new_component_block) { proc { } }

    it "adds the new component into to components" do
      subject.add_component(new_component_name, new_component_class, new_component_option, &new_component_block)
      expect(subject.components[new_component_name]).to eq({class_name: new_component_class, options: new_component_option, block: new_component_block})
    end
  end
  describe "#remove_component" do
    let(:new_component_name) { :new_name }
    let(:new_component_class) { 'Component' }
    let(:new_component_option) { {} }
    let(:new_component_block) { proc { } }
    before do
      subject.add_component(new_component_name, new_component_class, new_component_option, &new_component_block)
    end

    it "removes the new component from components" do
      expect(subject.components[new_component_name]).not_to be nil
      subject.remove_component(new_component_name)
      expect(subject.components.has_key?(new_component_name)).to be false
    end
  end

end
