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
            "vms"     => [@vm.to_internal_structure]
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

        def to_internal_structure
          {
            "name"    => @name,
            "box"     => @box,
            "box_url" => @box_url
          }
        end
      end
    end
  end
end
