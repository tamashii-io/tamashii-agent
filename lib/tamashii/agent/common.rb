require 'tamashii/agent/common/loggable'

module Tamashii
  module Agent
    module Common

      def self.load_device_class(device_class_name)
        full_class_name = 'Tamashii::Agent::Device::' + device_class_name 
        load_class(full_class_name)
      end

      def self.load_class(class_name)
        path = get_class_path(class_name)
        require path
        Module.const_get(class_name)
      end

      def self.get_class_path(class_name)
        string_underscore(class_name)
      end

      def self.string_underscore(original)
        word = original.dup
        word.gsub!(/::/, '/')
        word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        word.tr!("-", "_")
        word.downcase!
        word
      end
    end
  end
end
