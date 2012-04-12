require "omniconfig"

module Vagrant
  module Config
    module V1
      class VM < OmniConfig::Structure
        def initialize(env)
          super()

          @env = env

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

          define("auto_port_range", OmniConfig::Type::List.new(OmniConfig::Type::Integer))
          define("base_mac", OmniConfig::Type::String)
          define("boot_mode", OmniConfig::Type::String)
          define("box", OmniConfig::Type::String)
          define("box_url", OmniConfig::Type::String)
          define("forwarded_ports", OmniConfig::Type::List.new(forwarded_port_type))
          define("guest", OmniConfig::Type::String)
          define("name", OmniConfig::Type::String)
          define("primary", OmniConfig::Type::Bool)
          define("shared_folders", OmniConfig::Type::List.new(shared_folder_type))
        end

        # Little helper to check that a value is set and is truthy.
        #
        # @return [Boolean]
        def value_set(value)
          value != OmniConfig::UNSET_VALUE && value
        end

        def validate(errors, value)
          box = value["box"]
          box = nil if box == OmniConfig::UNSET_VALUE
          errors.add(I18n.t("vagrant.config.vm.box_missing")) if !value_set(box)

          if box && !value_set(value["box_url"]) && !@env.boxes.find(box)
            errors.add(I18n.t("vagrant.config.vm.box_not_found", :name => box))
          end

          errors.add(I18n.t("vagrant.config.vm.boot_mode_invalid")) if !["headless", "gui"].include?(value["boot_mode"])
          errors.add(I18n.t("vagrant.config.vm.base_mac_invalid")) if @env.boxes.find(box) && !base_mac

=begin
          shared_folders.each do |name, options|
            hostpath = Pathname.new(options[:hostpath]).expand_path(env.root_path)

            if !hostpath.directory? && !options[:create]
              errors.add(I18n.t("vagrant.config.vm.shared_folder_hostpath_missing",
                                :name => name,
                                :path => options[:hostpath]))
            end

            if options[:nfs] && (options[:owner] || options[:group])
              # Owner/group don't work with NFS
              errors.add(I18n.t("vagrant.config.vm.shared_folder_nfs_owner_group",
                                :name => name))
            end
          end

          # Validate some basic networking
          #
          # TODO: One day we need to abstract this out, since in the future
          # providers other than VirtualBox will not be able to satisfy
          # all types of networks.
          networks.each do |type, args|
            if type == :hostonly && args[0] == :dhcp
              # Valid. There is no real way this can be invalid at the moment.
            elsif type == :hostonly
              # Validate the host-only network
              ip      = args[0]
              options = args[1] || {}

              if !ip
                errors.add(I18n.t("vagrant.config.vm.network_ip_required"))
              else
                ip_parts = ip.split(".")

                if ip_parts.length != 4
                  errors.add(I18n.t("vagrant.config.vm.network_ip_invalid",
                                    :ip => ip))
                elsif ip_parts.last == "1"
                  errors.add(I18n.t("vagrant.config.vm.network_ip_ends_one",
                                    :ip => ip))
                end
              end
            elsif type == :bridged
            else
              # Invalid network type
              errors.add(I18n.t("vagrant.config.vm.network_invalid",
                                :type => type.to_s))
            end
          end

          # Each provisioner can validate itself
          provisioners.each do |prov|
            prov.validate(env, errors)
          end
=end
        end
      end
    end
  end
end
