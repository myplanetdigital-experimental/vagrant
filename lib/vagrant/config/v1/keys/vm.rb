require "omniconfig"

module Vagrant
  module Config
    module V1
      module Keys
        class VM < OmniConfig::Structure
          def initialize
            super

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
        end
      end
    end
  end
end
