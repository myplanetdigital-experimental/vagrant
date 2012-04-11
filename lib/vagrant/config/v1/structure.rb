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

          define("id", OmniConfig::Type::String)

          # Load in all the version 1 config keys
          Vagrant.config_keys["1"].each do |key, type|
            define(key, type)
          end
        end
      end
    end
  end
end
