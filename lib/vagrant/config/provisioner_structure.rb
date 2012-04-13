require "omniconfig"

module Vagrant
  module Config
    class ProvisionerStructure < OmniConfig::Structure
      def initialize(opts=nil)
        super()

        opts = {
          :registry => Vagrant.provisioners
        }.merge(opts || {})

        # Store the registry we'll use to look up provisioners
        @registry = opts[:registry]

        # This must be set to the actual type of the provisioner.
        # The rest of the contents of this structure are used to
        # configure the provisioner itself, with that structure
        # being based off of this structure.
        define("provisioner_type", OmniConfig::Type::String)
      end

      def value(raw)
        # We require a Hash to be given to us.
        raise OmniConfig::TypeError if !raw.is_a?(Hash)

        # If we don't have a provisioner type, just return
        return raw if !raw.has_key?("provisioner_type")

        # Get the configuration class
        type_name   = raw["provisioner_type"]
        provisioner = @registry.get(type_name.to_sym)
        type        = provisioner.config_class

        # Get the value determined by the provisioner class
        value = type.instance.value(raw)

        # Merge in the provisioner type so that is always available
        value.merge("provisioner_type" => type_name)
      end
    end
  end
end
