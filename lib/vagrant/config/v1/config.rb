module Vagrant
  module Config
    module V1
      # This is the actual `config` object passed into Vagrantfiles for
      # version 1 configurations. The primary responsibility of this class
      # is to provide a configuration API while translating down to the proper
      # OmniConfig schema at the end of the day.
      class Config
        attr_reader :ssh
        attr_reader :vagrant
        attr_reader :vm

        def initialize
          @ssh     = SSHConfig.new
          @vagrant = VagrantConfig.new
          @vm = VMConfig.new
        end

        def to_internal_structure
          {
            "ssh"     => @ssh.to_internal_structure,
            "vagrant" => @vagrant.to_internal_structure,
            "vms"     => @vm.to_internal_structure
          }
        end
      end

      # The `config.ssh` object.
      class SSHConfig
        attr_accessor :username
        attr_accessor :password
        attr_accessor :host
        attr_accessor :port
        attr_accessor :guest_port
        attr_accessor :max_tries
        attr_accessor :timeout
        attr_accessor :private_key_path
        attr_accessor :forward_agent
        attr_accessor :forward_x11
        attr_accessor :shell

        def to_internal_structure
          {
            "username" => @username,
            "password" => @password,
            "host"     => @host,
            "port"     => @port,
            "guest_port" => @guest_port,
            "max_tries" => @max_tries,
            "timeout"  => @timeout,
            "private_key_path" => @private_key_path,
            "forward_agent" => @forward_agent,
            "forward_x11"   => @forward_x11,
            "shell"         => @shell
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
        attr_accessor :auto_port_range
        attr_accessor :box
        attr_accessor :box_url
        attr_accessor :base_mac
        attr_accessor :boot_mode
        attr_accessor :guest
        attr_accessor :host_name
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
          {
            "name"    => @name,
            "auto_port_range" => @auto_port_range,
            "base_mac" => @base_mac,
            "boot_mode" => @boot_mode,
            "box"     => @box,
            "box_url" => @box_url,
            "guest"   => @guest,
            "host_name" => @host_name,
            "primary" => @primary
          }
        end

        def to_internal_structure
          vms = []
          if @defined_vms.empty?
            # We are the only VM. This is good.
            vms << to_internal_structure_flat
          else
            # We have multiple VMs, so just get them in the array in the
            # right order. Note that we don't deal with inheritance. In our
            # view of the world, there is no such thing. Ruby Vagrantfiles
            # do support inheritance however, and that is handled by the
            # config loader itself.
            @defined_vms_order.each do |name|
              vms << @defined_vms[name].to_internal_structure_flat
            end
          end

          vms
        end
      end
    end
  end
end
