require "omniconfig"

module Vagrant
  module Config
    module V1
      module Keys
        class NFS < OmniConfig::Structure
          def initialize
            super

            define("map_uid", OmniConfig::Type::String)
            define("map_gid", OmniConfig::Type::String)
          end
        end
      end
    end
  end
end
