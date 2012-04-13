require "omniconfig"

module Vagrant
  module Config
    class ProvisionerStructure < OmniConfig::Structure
      def initialize
        super()

        # This must be set to the actual Ruby class that the provisioner
        # is configured with.
        define("provisioner_class", OmniConfig::Type::Any)
      end

      def value(raw)
        # We require a Hash to be given to us.
        raise OmniConfig::TypeError if !raw.is_a?(Hash)

        # If we don't have a provisioner type, just return
        return raw if !raw.has_key?("provisioner_class")

        # Get the configuration class
        provisioner = raw["provisioner_class"]
        type        = provisioner.config_class

        # Get the value determined by the provisioner class
        value = type.instance.value(raw)

        # Merge in the provisioner type so that is always available
        value.merge("provisioner_class" => provisioner)
      end
    end
  end
end
