require "omniconfig"

module Vagrant
  module Config
    module V1
      class SSH < OmniConfig::Structure
        def initialize
          super

          define("username", OmniConfig::Type::String)
          define("password", OmniConfig::Type::String)
          define("host", OmniConfig::Type::String)
          define("port", OmniConfig::Type::Integer)
          define("guest_port", OmniConfig::Type::Integer)
          define("max_tries", OmniConfig::Type::Integer)
          define("timeout", OmniConfig::Type::Integer)
          define("private_key_path", OmniConfig::Type::String)
          define("forward_agent", OmniConfig::Type::Bool)
          define("forward_x11", OmniConfig::Type::Bool)
          define("shell", OmniConfig::Type::String)
        end
      end
    end
  end
end
