module Vagrant
  module Config
    module V1
      module Keys
        # This returns the configuration keys for this version.
        def self.config_keys
          {
            "nfs"     => NFS,
            "package" => Package,
            "ssh"     => SSH,
            "vagrant" => Vagrant,
            "vm"      => VM
          }
        end
      end
    end
  end
end
