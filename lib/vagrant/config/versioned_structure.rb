require "omniconfig"

module Vagrant
  module Config
    # This is the configuration structure for a specific version of the
    # configuration.
    class VersionedStructure < OmniConfig::Structure
      def initialize(env, version)
        super()

        # Every structure has an "id" field which is a unique identifier
        # for this configuration.
        define("id", OmniConfig::Type::String)

        # Get the config keys that are on the version itself if they're
        # available.
        version_class = Vagrant::Config::VERSIONS.get(version)
        version_class.config_keys.each do |key, type|
          define(key, type.new(env))
        end

        # Get the various parts from the config_keys registry.
        Vagrant.config_keys.each do |key, type|
          define(key, type.new(env))
        end
      end
    end
  end
end
