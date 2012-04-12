require "vagrant/util/template_renderer"

module Vagrant
  module Config
    # This wraps the settings and provides dictionary access as well
    # as some helper methods. This is the actual class returned for
    # configuration.
    class Wrapper
      def initialize(omniconfig, settings)
        @omniconfig = omniconfig
        @settings   = settings
      end

      # Provides hash-like access to the underlying settings.
      def [](key)
        @settings[key]
      end

      # Returns the actual hash of settings.
      def to_hash
        @settings
      end

      # Validates this configuration. The bang ("!") on this method
      # is to show that this will throw an exception if there is an
      # error, rather than returning false.
      def validate!
        @omniconfig.validate(@settings)
        true
      rescue OmniConfig::InvalidConfiguration => e
        messages = Util::TemplateRenderer.render("config/validation_failed",
                                                 :errors => e.errors)
        raise Errors::ConfigValidationFailed, :messages => messages
      end
    end
  end
end
