require "omniconfig"

module Vagrant
  module Config
    module V1
      class Package < OmniConfig::Structure
        def initialize
          super

          define("name", OmniConfig::Type::String)
        end
      end
    end
  end
end
