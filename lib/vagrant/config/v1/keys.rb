module Vagrant
  module Config
    module V1
      module Keys
        autoload :NFS,     'vagrant/config/v1/keys/nfs'
        autoload :Package, 'vagrant/config/v1/keys/package'
        autoload :SSH,     'vagrant/config/v1/keys/ssh'
        autoload :Vagrant, 'vagrant/config/v1/keys/vagrant'
        autoload :VM,      'vagrant/config/v1/keys/vm'
      end
    end
  end
end
