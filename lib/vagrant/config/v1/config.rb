module Vagrant
  module Config
    module V1
      # This is the actual `config` object passed into Vagrantfiles for
      # version 1 configurations. The primary responsibility of this class
      # is to provide a configuration API while translating down to the proper
      # OmniConfig schema at the end of the day.
      class Config
        attr_reader :ssh
        attr_reader :nfs
        attr_reader :package
        attr_reader :vagrant
        attr_reader :vm

        def initialize(id=nil)
          @subvm   = !id.nil?
          @id      = id
          @nfs     = NFSConfig.new
          @package = PackageConfig.new
          @ssh     = SSHConfig.new
          @vagrant = VagrantConfig.new
          @vm      = VMConfig.new(@subvm)
        end

        def to_internal_structure
          current = {
            "id"      => @id,
            "nfs"     => @nfs.to_internal_structure,
            "package" => @package.to_internal_structure,
            "ssh"     => @ssh.to_internal_structure,
            "vagrant" => @vagrant.to_internal_structure,
            "vm"      => @vm.to_internal_structure_flat
          }

          if @subvm
            # If we represent a sub-VM configuration, then we return the
            # internal structure with VM being just the single VM.
            return current
          else
            # We are the top-level configuration object, so we need to return
            # the "outer" being what we have here now along with an array of
            # sub-VMs.
            return {
              "global" => current,
              "vms"    => @vm.to_internal_structure_vms
            }
          end
        end
      end

      # The `config.nfs` object.
      class NFSConfig
        attr_accessor :map_uid
        attr_accessor :map_gid

        def initialize
          @map_uid = OmniConfig::UNSET_VALUE
          @map_gid = OmniConfig::UNSET_VALUE
        end

        def to_internal_structure
          {
            "map_uid" => @map_uid,
            "map_gid" => @map_gid
          }
        end
      end

      # The `config.package` object.
      class PackageConfig
        attr_accessor :name

        def initialize
          @name = OmniConfig::UNSET_VALUE
        end

        def to_internal_structure
          {
            "name" => @name
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

        def initialize
          @username = OmniConfig::UNSET_VALUE
          @password = OmniConfig::UNSET_VALUE
          @host     = OmniConfig::UNSET_VALUE
          @port     = OmniConfig::UNSET_VALUE
          @guest_port = OmniConfig::UNSET_VALUE
          @max_tries  = OmniConfig::UNSET_VALUE
          @timeout    = OmniConfig::UNSET_VALUE
          @private_key_path = OmniConfig::UNSET_VALUE
          @forward_agent = OmniConfig::UNSET_VALUE
          @forward_x11   = OmniConfig::UNSET_VALUE
          @shell    = OmniConfig::UNSET_VALUE
        end

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

        def initialize
          @dotfile_name = OmniConfig::UNSET_VALUE
          @host         = OmniConfig::UNSET_VALUE
        end

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

        # Initializes a new VM configurartion object. If `subvm` is
        # set to true then this configuration represents a sub-VM.
        def initialize(subvm=false)
          @subvm = subvm
          @defined_vms = {}
          @defined_vms_order = []
          @forwarded_ports = []
          @shared_folders = {}

          @name = OmniConfig::UNSET_VALUE
          @auto_port_range = OmniConfig::UNSET_VALUE
          @box = OmniConfig::UNSET_VALUE
          @box_url = OmniConfig::UNSET_VALUE
          @base_mac = OmniConfig::UNSET_VALUE
          @boot_mode = OmniConfig::UNSET_VALUE
          @guest = OmniConfig::UNSET_VALUE
          @host_name = OmniConfig::UNSET_VALUE
          @primary = false
        end

        # Define a sub-VM. This takes a block which will be called
        # with another `config` object. The config object can be used
        # to specifically configure that virtual machine.
        def define(name, options=nil, &block)
          name    = name.to_s
          options ||= {}

          # Configure the sub-VM.
          config  = Config.new(name)
          block.call(config) if block

          # Set some options on this
          config.vm.name    = name
          config.vm.primary = true if options[:primary]

          # Assign the VM and record the order that it was defined
          @defined_vms[name] = config
          @defined_vms_order << name
        end

        def forward_port(guestport, hostport, options=nil)
          # Stringify the keys of the options hash
          options ||= {}
          options.keys.each do |key|
            options[key.to_s] = options[key]
          end

          # Store the forwarded port definition
          @forwarded_ports << {
            "name"       => "#{guestport.to_s(32)}-#{hostport.to_s(32)}",
            "guestport"  => guestport,
            "hostport"   => hostport,
            "protocol"   => :tcp,
            "adapter"    => 1,
            "auto"       => false
          }.merge(options || {})
        end

        def share_folder(name, guestpath, hostpath, options=nil)
          # Stringify the keys of the options hash
          options ||= {}
          options.keys.each do |key|
            options[key.to_s] = options[key]
          end

          @shared_folders[name] = {
            "name"      => name,
            "guestpath" => guestpath.to_s,
            "hostpath" => hostpath.to_s,
            "create" => false,
            "owner" => nil,
            "group" => nil,
            "nfs"   => false,
            "transient" => false,
            "extra" => nil
          }.merge(options || {})
        end

        # Convert to the "flat" internal structure that is used for
        # only one virtual machine.
        def to_internal_structure_flat
          {
            "name"    => @name,
            "auto_port_range" => @auto_port_range,
            "base_mac" => @base_mac,
            "boot_mode" => @boot_mode,
            "box"     => @box,
            "box_url" => @box_url,
            "forwarded_ports" => @forwarded_ports,
            "guest"   => @guest,
            "host_name" => @host_name,
            "primary" => @primary,
            "shared_folders" => @shared_folders.values
          }
        end

        # Construct a list of VMs that were created.
        def to_internal_structure_vms
          # If we have no sub-VMs we return an empty configuration because the
          # global VM configuration is what is used.
          return [] if @defined_vms_order.empty?

          # Return each of the sub-VM's configuration.
          @defined_vms_order.map do |name|
            @defined_vms[name].to_internal_structure
          end
        end
      end
    end
  end
end
