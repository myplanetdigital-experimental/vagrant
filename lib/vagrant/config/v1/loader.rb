require "vagrant/config/v1/config"

module Vagrant
  module Config
    module V1
      # This is a loader for OmniConfig which takes a Proc and properly
      # runs it and translates it into the version 1 Vagrant configuration.
      class Loader
        # Initialize the loader with the given configuration proc.
        #
        # The proc should take one argument which is the `config` object,
        # as version 1 Vagrantfiles did. This proc will be run when the loader
        # runs. This is a loder that conforms properly to the global configuration
        # structure.
        def initialize(config_proc)
          @proc = config_proc
        end

        # Runs the actual proc and returns something that hopefully matches
        # the given schema.
        def load(schema)
          # Create a new top-level configuration object
          config = Config.new

          # Run our proc on this configuration object
          @proc.call(config)

          # Return what we got
          return config.to_internal_structure
        end
      end
    end
  end
end
