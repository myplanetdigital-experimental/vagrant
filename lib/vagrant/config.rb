module Vagrant
  module Config
    autoload :Base,          'vagrant/config/base'
    autoload :Container,     'vagrant/config/container'
    autoload :ErrorRecorder, 'vagrant/config/error_recorder'
    autoload :HashWrapper,   'vagrant/config/hash_wrapper'
    autoload :ProcLoader,    'vagrant/config/proc_loader'
    autoload :Structure,     'vagrant/config/structure'
    autoload :VersionedStructure, 'vagrant/config/versioned_structure'
    autoload :Wrapper,       'vagrant/config/wrapper'

    autoload :V1,            'vagrant/config/v1'

    # These are the available configuration versions.
    VERSIONS = Registry.new do |r|
      r.register("1") { V1 }
    end

    CONFIGURE_MUTEX = Mutex.new

    # This is the method which is called by all Vagrantfiles to configure Vagrant.
    # This method expects a block which accepts a single argument representing
    # an instance of the {Config::Top} class.
    #
    # Note that the block is not run immediately. Instead, it's proc is stored
    # away for execution later.
    def self.run(version=nil, &block)
      # If the version isn't specified, we assume version 1.0, since prior to
      # 1.0 this didn't take a version parameter.
      version ||= "1"

      # Store it for later
      @last_procs ||= []
      @last_procs << [version, block]
    end

    # This is a method which will yield to a block and will capture all
    # ``Vagrant.configure`` calls, returning an array of `Proc`s.
    #
    # Wrapping this around anytime you call code which loads configurations
    # will force a mutex so that procs never get mixed up. This keeps
    # the configuration loading part of Vagrant thread-safe.
    #
    # @return [Array] Array of procs in the format `[version, block]`.
    def self.capture_configures
      CONFIGURE_MUTEX.synchronize do
        # Reset the last procs so that we start fresh
        @last_procs = []

        # Yield to allow the caller to do whatever loading needed
        yield

        # Return the last procs we've seen while still in the mutex,
        # knowing we're safe.
        return @last_procs
      end
    end
  end
end
