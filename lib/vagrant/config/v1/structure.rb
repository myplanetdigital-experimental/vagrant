require "omniconfig"

module Vagrant
  module Config
    module V1
      # Version 1 Vagrant configuration.
      #
      # This is the configuration structure that represents a valid
      # configuration for version 1 of Vagrant. Version 1 Vagrantfiles
      # translate into this structure.
      class Structure < OmniConfig::Structure
        def initialize
          super

          # This represents the global `vagrant` configuration
          vagrant_type = OmniConfig::Structure.new do |s|
            s.define("dotfile_name", OmniConfig::Type::String)
            s.define("host", OmniConfig::Type::String)
          end

          # This represents a single VM within the configuration
          vm_type = OmniConfig::Structure.new do |s|
            s.define("name", OmniConfig::Type::String)
            s.define("box", OmniConfig::Type::String)
            s.define("box_url", OmniConfig::Type::String)
            s.define("primary", OmniConfig::Type::Bool)
          end

          # Define members of this structure
          define("vagrant", vagrant_type)
          define("vms", OmniConfig::Type::List.new(vm_type))
        end
      end
    end
  end
end
