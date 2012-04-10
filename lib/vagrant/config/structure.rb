require "omniconfig"

module Vagrant
  module Config
    # Every configuration version must at the very least return
    # this structure. The structure is as follows:
    #
    # * "global" - The global configuration. This is merged into each
    #   VM configuration.
    # * "vms" - An array of VM definitions.
    class Structure < OmniConfig::Structure
      # Initialize a configuration structure for the given versioned
      # structure.
      #
      # @param [OmniConfig::Structure] versioned_struct The structure of
      #   the configuration.
      def initialize(versioned_struct)
        super()

        @versioned_struct = versioned_struct

        define("global", versioned_struct)
        define("vms", OmniConfig::Type::List.new(versioned_struct))
      end

      # Custom merging behavior when merging a specific member. This
      # handles properly merging VMs.
      def merge_member(key, type, old, new)
        # We only care about the "vms" member
        return super if key != "vms"

        # Create a mapping to the new VMs by names
        new_by_id = {}
        new.each do |new_vm|
          new_by_id[new_vm["id"]] = new_vm
        end

        # Iterate over the old VMs, adding them to the result set first
        # since they were defined earlier. These are merged with the newer
        # VMs if they share the same ID.
        merged = []
        result = []
        old.each do |old_vm|
          if !new_by_id.has_key?(old_vm["id"])
            result << old_vm
          else
            result << @versioned_struct.merge(old_vm, new_by_id[old_vm["id"]])
            merged << old_vm["id"]
          end
        end

        # Go over the new VM definitions, only adding those to the result
        # set that weren't merged earlier.
        new.each do |new_vm|
          result << new_vm if !merged.include?(new_vm["id"])
        end

        result
      end
    end
  end
end
