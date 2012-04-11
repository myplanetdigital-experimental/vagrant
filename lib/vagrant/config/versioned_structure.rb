require "omniconfig"

module Vagrant
  module Config
    # This is the configuration structure for a specific version of the
    # configuration.
    class VersionedStructure < OmniConfig::Structure
      def initialize(version)
        super()

        define("id", OmniConfig::Type::String)

        # Get the various parts from the config_keys registry.
        Vagrant.config_keys[version].each do |key, type|
          define(key, type)
        end
      end
    end
  end
end
