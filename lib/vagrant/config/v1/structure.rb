require "omniconfig"

module Vagrant
  module Config
    module V1
      # Version 1 Vagrant configuration.
      #
      # This is the configuration structure that represents a valid
      # configuration for version 1 of Vagrant. Version 1 Vagrantfiles
      # translate into this structure.
      class Structure < OmniConfig::Structure
        def initialize
          super

          # This represents the global `nfs` configuration
          nfs_type = OmniConfig::Structure.new do |s|
            s.define("map_uid", OmniConfig::Type::String)
            s.define("map_gid", OmniConfig::Type::String)
          end

          # This represents the global 'package' configuration
          package_type = OmniConfig::Structure.new do |s|
            s.define("name", OmniConfig::Type::String)
          end

          # This represents the global `ssh` configuration
          ssh_type = OmniConfig::Structure.new do |s|
            s.define("username", OmniConfig::Type::String)
            s.define("password", OmniConfig::Type::String)
            s.define("host", OmniConfig::Type::String)
            s.define("port", OmniConfig::Type::Integer)
            s.define("guest_port", OmniConfig::Type::Integer)
            s.define("max_tries", OmniConfig::Type::Integer)
            s.define("timeout", OmniConfig::Type::Integer)
            s.define("private_key_path", OmniConfig::Type::String)
            s.define("forward_agent", OmniConfig::Type::Bool)
            s.define("forward_x11", OmniConfig::Type::Bool)
            s.define("shell", OmniConfig::Type::String)
          end

          # This represents the global `vagrant` configuration
          vagrant_type = OmniConfig::Structure.new do |s|
            s.define("dotfile_name", OmniConfig::Type::String)
            s.define("host", OmniConfig::Type::String)
          end

          # This represents a single VM within the configuration
          vm_type = OmniConfig::Structure.new do |s|
            forwarded_port_type = OmniConfig::Structure.new do |fp|
              fp.define("name", OmniConfig::Type::String)
              fp.define("guestport", OmniConfig::Type::Integer)
              fp.define("hostport", OmniConfig::Type::Integer)
              fp.define("protocol", OmniConfig::Type::String)
              fp.define("adapter", OmniConfig::Type::Integer)
              fp.define("auto", OmniConfig::Type::Bool)
            end

            shared_folder_type = OmniConfig::Structure.new do |sf|
              sf.define("name", OmniConfig::Type::String)
              sf.define("guestpath", OmniConfig::Type::String)
              sf.define("hostpath", OmniConfig::Type::String)
              sf.define("create", OmniConfig::Type::Bool)
              sf.define("owner", OmniConfig::Type::String)
              sf.define("group", OmniConfig::Type::String)
              sf.define("nfs", OmniConfig::Type::Bool)
              sf.define("transient", OmniConfig::Type::Bool)
              sf.define("extra", OmniConfig::Type::Any)
            end

            s.define("auto_port_range", OmniConfig::Type::List.new(OmniConfig::Type::Integer))
            s.define("base_mac", OmniConfig::Type::String)
            s.define("boot_mode", OmniConfig::Type::String)
            s.define("box", OmniConfig::Type::String)
            s.define("box_url", OmniConfig::Type::String)
            s.define("forwarded_ports", OmniConfig::Type::List.new(forwarded_port_type))
            s.define("guest", OmniConfig::Type::String)
            s.define("name", OmniConfig::Type::String)
            s.define("primary", OmniConfig::Type::Bool)
            s.define("shared_folders", OmniConfig::Type::List.new(shared_folder_type))
          end

          # Define members of this structure
          define("nfs", nfs_type)
          define("package", package_type)
          define("ssh", ssh_type)
          define("vagrant", vagrant_type)
          define("vms", OmniConfig::Type::List.new(vm_type))
        end
      end
    end
  end
end
