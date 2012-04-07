module Vagrant
  module Config
    module V1
      # This is the actual `config` object passed into Vagrantfiles for
      # version 1 configurations. The primary responsibility of this class
      # is to provide a configuration API while translating down to the proper
      # OmniConfig schema at the end of the day.
      class Config
        attr_reader :vagrant
        attr_reader :vm

        def initialize
          @vagrant = VagrantConfig.new
          @vm = VMConfig.new
        end

        def to_internal_structure
          # XXX: For now we only support 1 VM
          {
            "vagrant" => @vagrant.to_internal_structure,
            "vms"     => @vm.to_internal_structure
          }
        end
      end

      # The `config.vagrant` object.
      class VagrantConfig
        attr_accessor :dotfile_name
        attr_accessor :host

        def to_internal_structure
          {
            "dotfile_name" => @dotfile_name,
            "host"         => @host
          }
        end
      end

      # The `config.vm` object.
      class VMConfig
        attr_accessor :name
        attr_accessor :box
        attr_accessor :box_url
        attr_accessor :primary

        def initialize
          @defined_vms = {}
          @defined_vms_order = []
        end

        def define(name, options=nil, &block)
          name    = name.to_s
          options ||= {}

          # Configure the sub-VM.
          config  = self.class.new
          block.call(config) if block

          # Set some options on this
          config.name    = name
          config.primary = true if options[:primary]

          # Assign the VM and record the order that it was defined
          @defined_vms[name] = config
          @defined_vms_order << name
        end

        def to_internal_structure_flat(parent=nil)
          result = {
            "name"    => @name,
            "box"     => @box,
            "box_url" => @box_url,
            "primary" => @primary
          }

          # Handle inheritance
          if parent
            result.each do |key, value|
              result[key] = parent[key] if result[key].nil? && parent[key]
            end
          end

          result
        end

        def to_internal_structure
          vms = []
          if @defined_vms.empty?
            # We are the only VM. This is good.
            vms << to_internal_structure_flat
          else
            # Get our flat internals for inheritance
            parent = to_internal_structure_flat

            # We have multiple VMs, so just get them in the array in the
            # right order, properly inheriting.
            @defined_vms_order.each do |name|
              vms << @defined_vms[name].to_internal_structure_flat(parent)
            end
          end

          vms
        end
      end
    end
  end
end
