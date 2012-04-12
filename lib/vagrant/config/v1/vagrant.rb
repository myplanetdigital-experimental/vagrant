require "omniconfig"

module Vagrant
  module Config
    module V1
      class Vagrant < OmniConfig::Structure
        def initialize(env)
          super()

          define("dotfile_name", OmniConfig::Type::String)
          define("host", OmniConfig::Type::String)
        end

        def validate(errors, value)
          key = "dotfile_name"
          if value[key] == OmniConfig::UNSET_VALUE || !value[key]
            errors.add(I18n.t("vagrant.config.common.error_empty", :field => key))
          end
        end
      end
    end
  end
end
