module Vagrant
  module Config
    module V1
      autoload :Keys,      'vagrant/config/v1/keys'
      autoload :Loader,    'vagrant/config/v1/loader'
      autoload :NFS,       'vagrant/config/v1/nfs'
      autoload :Package,   'vagrant/config/v1/package'
      autoload :SSH,       'vagrant/config/v1/ssh'
      autoload :Vagrant,   'vagrant/config/v1/vagrant'
      autoload :VM,        'vagrant/config/v1/vm'

      # This returns the configuration keys for this version.
      #
      # @return [Hash]
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
