module Vagrant
  module Action
    module VM
      class ProvisionerCleanup
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          enabled_provisioners.each do |instance|
            instance.cleanup
          end

          @app.call(env)
        end

        def enabled_provisioners
          @env[:vm].config["vm"]["provisioners"].each do |config|
            config["provisioner_class"].new(@env, config)
          end
        end
      end
    end
  end
end
