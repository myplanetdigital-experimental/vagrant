require "omniconfig"

module Vagrant
  module Config
    module V1
      # Version 1 Vagrant configuration.
      #
      # This is the configuration structure that represents a valid
      # configuration for version 1 of Vagrant. Version 1 Vagrantfiles
      # translate into this structure.
      class Config < OmniConfig::Structure
        def initialize
          super

          # This represents a single VM within the configuration
          vm_type = OmniConfig::Structure.new do |s|
            s.define("name", OmniConfig::Type::String)
            s.define("box", OmniConfig::Type::String)
            s.define("box_url", OmniConfig::Type::String)
          end

          # Our configuration is really just an array of virtual machine
          # configurations.
          define("vms", OmniConfig::Type::List.new(vm_type))
        end
      end
    end
  end
end
