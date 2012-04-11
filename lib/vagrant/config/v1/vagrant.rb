require "omniconfig"

module Vagrant
  module Config
    module V1
      class Vagrant < OmniConfig::Structure
        def initialize
          super

          define("dotfile_name", OmniConfig::Type::String)
          define("host", OmniConfig::Type::String)
        end
      end
    end
  end
end
