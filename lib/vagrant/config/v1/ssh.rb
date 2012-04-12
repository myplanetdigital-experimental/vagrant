require "omniconfig"

module Vagrant
  module Config
    module V1
      class SSH < OmniConfig::Structure
        def initialize(env)
          super()

          @env = env

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

        def validate(errors, value)
          required = ["username", "host", "max_tries", "timeout"]
          required.each do |key|
            if value[key] == OmniConfig::UNSET_VALUE || !value[key]
              errors.add(I18n.t("vagrant.config.common.error_empty", :field => key))
            end
          end

          private_key_path = value["private_key_path"]
          if private_key_path != OmniConfig::UNSET_VALUE && private_key_path
            # Verify the private key file actually exists
            expanded_path = File.expand_path(private_key_path, @env.root_path)
            if !File.file?(expanded_path)
              errors.add(I18n.t("vagrant.config.ssh.private_key_missing",
                                :path => private_key_path))
            end
          end
        end
      end
    end
  end
end
