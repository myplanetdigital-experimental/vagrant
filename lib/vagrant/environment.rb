require 'pathname'
require 'fileutils'

require 'log4r'
require 'omniconfig'
require 'rubygems'  # This is needed for plugin loading below.

require 'vagrant/util/file_mode'
require 'vagrant/util/platform'

module Vagrant
  # Represents a single Vagrant environment. A "Vagrant environment" is
  # defined as basically a folder with a "Vagrantfile." This class allows
  # access to the VMs, CLI, etc. all in the scope of this environment.
  class Environment
    HOME_SUBDIRS = ["tmp", "boxes", "gems"]
    DEFAULT_VM = :default
    DEFAULT_HOME = "~/.vagrant.d"

    # The `cwd` that this environment represents
    attr_reader :cwd

    # The valid name for a Vagrantfile for this environment.
    attr_reader :vagrantfile_name

    # The {UI} object to communicate with the outside world.
    attr_reader :ui

    # The directory to the "home" folder that Vagrant will use to store
    # global state.
    attr_reader :home_path

    # The directory where temporary files for Vagrant go.
    attr_reader :tmp_path

    # The directory where boxes are stored.
    attr_reader :boxes_path

    # The path where the plugins are stored (gems)
    attr_reader :gems_path

    # The path to the default private key
    attr_reader :default_private_key_path

    # Initializes a new environment with the given options. The options
    # is a hash where the main available key is `cwd`, which defines where
    # the environment represents. There are other options available but
    # they shouldn't be used in general. If `cwd` is nil, then it defaults
    # to the `Dir.pwd` (which is the cwd of the executing process).
    def initialize(opts=nil)
      opts = {
        :cwd => nil,
        :vagrantfile_name => nil,
        :lock_path => nil,
        :ui_class => nil,
        :home_path => nil
      }.merge(opts || {})

      # Set the default working directory to look for the vagrantfile
      opts[:cwd] ||= ENV["VAGRANT_CWD"] if ENV.has_key?("VAGRANT_CWD")
      opts[:cwd] ||= Dir.pwd
      opts[:cwd] = Pathname.new(opts[:cwd])
      raise Errors::EnvironmentNonExistentCWD if !opts[:cwd].directory?

      # Set the Vagrantfile name up. We append "Vagrantfile" and "vagrantfile" so that
      # those continue to work as well, but anything custom will take precedence.
      opts[:vagrantfile_name] ||= []
      opts[:vagrantfile_name] = [opts[:vagrantfile_name]] if !opts[:vagrantfile_name].is_a?(Array)
      opts[:vagrantfile_name] += ["Vagrantfile", "vagrantfile"]

      # Set instance variables for all the configuration parameters.
      @cwd    = opts[:cwd]
      @vagrantfile_name = opts[:vagrantfile_name]
      @lock_path = opts[:lock_path]
      @home_path = opts[:home_path]

      ui_class = opts[:ui_class] || UI::Silent
      @ui      = ui_class.new("vagrant")

      @loaded = false
      @lock_acquired = false

      @logger = Log4r::Logger.new("vagrant::environment")
      @logger.info("Environment initialized (#{self})")
      @logger.info("  - cwd: #{cwd}")

      # Setup the home directory
      setup_home_path
      @tmp_path = @home_path.join("tmp")
      @boxes_path = @home_path.join("boxes")
      @gems_path  = @home_path.join("gems")

      # Setup the default private key
      @default_private_key_path = @home_path.join("insecure_private_key")
      copy_insecure_private_key

      # Load the plugins
      load_plugins
    end

    #---------------------------------------------------------------
    # Helpers
    #---------------------------------------------------------------

    # The path to the `dotfile`, which contains the persisted UUID of
    # the VM if it exists.
    #
    # @return [Pathname]
    def dotfile_path
      return nil if !root_path
      root_path.join(@config_global["vagrant"]["dotfile_name"])
    end

    # Returns the collection of boxes for the environment.
    #
    # @return [BoxCollection]
    def boxes
      @_boxes ||= BoxCollection.new(boxes_path, action_runner)
    end

    # Returns the VMs associated with this environment.
    #
    # @return [Hash<Symbol,VM>]
    def vms
      load! if !loaded?
      @vms ||= load_vms!
    end

    # Returns the VMs associated with this environment, in the order
    # that they were defined.
    #
    # @return [Array<VM>]
    def vms_ordered
      return @vms.values if !multivm?
      @vms_enum ||= config.global.vms.map { |vm| vm["name"] }
    end

    # Returns the primary VM associated with this environment. This
    # method is only applicable for multi-VM environments. This can
    # potentially be nil if no primary VM is specified.
    #
    # @return [VM]
    def primary_vm
      return vms.values.first if !multivm?

      config.each do |name, vm_config|
        return vms[name] if vm_config["vm"]["primary"]
      end

      nil
    end

    # Returns a boolean whether this environment represents a multi-VM
    # environment or not. This will work even when called on child
    # environments.
    #
    # @return [Bool]
    def multivm?
      vms.length > 1 || vms.keys.first != DEFAULT_VM
    end

    # Makes a call to the CLI with the given arguments as if they
    # came from the real command line (sometimes they do!). An example:
    #
    #     env.cli("package", "--vagrantfile", "Vagrantfile")
    #
    def cli(*args)
      CLI.new(args.flatten, self).execute
    end

    # Returns the host object associated with this environment.
    #
    # @return [Hosts::Base]
    def host
      return @host if defined?(@host)

      # Attempt to figure out the host class. Note that the order
      # matters here, so please don't touch. Specifically: The symbol
      # check is done after the detect check because the symbol check
      # will return nil, and we don't want to trigger a detect load.
      host_klass = config_global["vagrant"]["host"]
      host_klass = Hosts.detect(Vagrant.hosts) if host_klass.nil? || host_klass == OmniConfig::UNSET_VALUE
      host_klass = Vagrant.hosts.get(host_klass) if host_klass.is_a?(Symbol)

      # If no host class is detected, we use the base class.
      host_klass ||= Hosts::Base

      @host ||= host_klass.new(@ui)
    end

    # Action runner for executing actions in the context of this environment.
    #
    # @return [Action::Runner]
    def action_runner
      @action_runner ||= Action::Runner.new(action_registry) do
        {
          :action_runner  => action_runner,
          :box_collection => boxes,
          :global_config  => @config_global,
          :host           => host,
          :root_path      => root_path,
          :tmp_path       => tmp_path,
          :ui             => @ui
        }
      end
    end

    # Action registry for registering new actions with this environment.
    #
    # @return [Registry]
    def action_registry
      # For now we return the global built-in actions registry. In the future
      # we may want to create an isolated registry that inherits from this
      # global one, but for now there isn't a use case that calls for it.
      Vagrant.actions
    end

    # Loads on initial access and reads data from the global data store.
    # The global data store is global to Vagrant everywhere (in every environment),
    # so it can be used to store system-wide information. Note that "system-wide"
    # typically means "for this user" since the location of the global data
    # store is in the home directory.
    #
    # @return [DataStore]
    def global_data
      @global_data ||= DataStore.new(File.expand_path("global_data.json", home_path))
    end

    # Loads (on initial access) and reads data from the local data
    # store. This file is always at the root path as the file "~/.vagrant"
    # and contains a JSON dump of a hash. See {DataStore} for more
    # information.
    #
    # @return [DataStore]
    def local_data
      @local_data ||= DataStore.new(dotfile_path)
    end

    # The root path is the path where the top-most (loaded last)
    # Vagrantfile resides. It can be considered the project root for
    # this environment.
    #
    # @return [String]
    def root_path
      return @root_path if defined?(@root_path)

      root_finder = lambda do |path|
        # Note: To remain compatible with Ruby 1.8, we have to use
        # a `find` here instead of an `each`.
        found = vagrantfile_name.find do |rootfile|
          File.exist?(File.join(path.to_s, rootfile))
        end

        return path if found
        return nil if path.root? || !File.exist?(path)
        root_finder.call(path.parent)
      end

      @root_path = root_finder.call(cwd)
    end

    # This returns the path which Vagrant uses to determine the location
    # of the file lock. This is specific to each operating system.
    def lock_path
      @lock_path || tmp_path.join("vagrant.lock")
    end

    # This locks Vagrant for the duration of the block passed to this
    # method. During this time, any other environment which attempts
    # to lock which points to the same lock file will fail.
    def lock
      # This allows multiple locks in the same process to be nested
      return yield if @lock_acquired

      File.open(lock_path, "w+") do |f|
        # The file locking fails only if it returns "false." If it
        # succeeds it returns a 0, so we must explicitly check for
        # the proper error case.
        raise Errors::EnvironmentLockedError if f.flock(File::LOCK_EX | File::LOCK_NB) === false

        begin
          # Mark that we have a lock
          @lock_acquired = true

          yield
        ensure
          # We need to make sure that no matter what this is always
          # reset to false so we don't think we have a lock when we
          # actually don't.
          @lock_acquired = false
        end
      end
    end

    #---------------------------------------------------------------
    # Config Methods
    #---------------------------------------------------------------

    # The configuration from the global scope of the Vagrantfiles.
    #
    # @return [Hash]
    def config_global
      load! if !loaded?
      @config_global
    end

    # The configuration by VM name. This will return a hash where the
    # key is the VM name (string) and the value is the configuration
    # (a Hash).
    #
    # @return [Hash]
    def config
      load! if !loaded?
      @config_by_vm
    end

    #---------------------------------------------------------------
    # Load Methods
    #---------------------------------------------------------------

    # Returns a boolean representing if the environment has been
    # loaded or not.
    #
    # @return [Bool]
    def loaded?
      !!@loaded
    end

    # Loads this entire environment, setting up the instance variables
    # such as `vm`, `config`, etc. on this environment. The order this
    # method calls its other methods is very particular.
    def load!
      if !loaded?
        @loaded = true
        @logger.info("Loading configuration...")
        load_config!
      end

      self
    end

    # Reloads the configuration of this environment.
    def reload!
      # Reload the configuration
      load_config!

      # Clear the VMs because this can now be diferent due to configuration
      @vms = nil
    end

    # Loads this environment's configuration and stores it in the {#config}
    # variable. The configuration loaded by this method is specified to
    # this environment, meaning that it will use the given root directory
    # to load the Vagrantfile into that context.
    def load_config!
      # This stores the configuration for various sources. We later merge
      # these configurations.
      config_by_source = {}
      default_path = File.expand_path("config/default.rb", Vagrant.source_root)
      config_by_source[:default] = find_and_load_vagrantfile(default_path)
      config_by_source[:home] = find_and_load_vagrantfile(home_path) if home_path
      config_by_source[:root] = find_and_load_vagrantfile(root_path) if root_path

      # Now that we have the set of configuration we can, we merged it all
      # together in order to get a proper list of VMs.
      @logger.debug("Loading global configuration...")
      global = merge_configs(Config::Structure.new(Config::V1::Structure),
                             config_by_source[:default],
                             config_by_source[:home],
                             config_by_source[:root])
      @config_global = global["global"]
      @logger.debug(global.inspect)

      # If no sub-VMs were defined, we define a single default VM that has
      # no specific configuration.
      if global["vms"].empty?
        global["vms"] << merge_configs(Config::V1::Structure.new, { "id" => DEFAULT_VM })
      end

      # For each virtual machine represented by this environment, we have
      # to load the configuration again, taking into account the VM's
      # box and the specific configuration for that VM.
      @config_by_vm = {}
      global["vms"].each do |vm_config|
        name = vm_config["id"].to_sym

        @logger.debug("Loading configuration for VM: #{name}...")
        @logger.debug("Raw VM config: #{vm_config.inspect}")

        # Get the box proc
        box_name = global["global"]["vm"]["box"]
        box_name = vm_config["vm"]["box"] if !box_name || box_name == OmniConfig::UNSET_VALUE
        box      = boxes.find(box_name)
        box_config = nil
        box_config = find_and_load_vagrantfile(box.directory) if box

        # Build up the chain of configs we're going to merge
        configs = []
        [:default, :home, box_config, :root].each do |type|
          type = config_by_source[type] if type.is_a?(Symbol)
          next if !type
          configs << type["global"]
        end
        configs << vm_config

        # Merge the configuration and assign it as the VM configuration
        config = merge_configs(Config::V1::Structure.new, *configs)
        @config_by_vm[name] = config
        @logger.debug("Merged '#{name}' VM config: #{config.inspect}")
      end
    end

    # This finds the Vagrantfile in the given path and returns the
    # procs associated with it.
    #
    # @param [String] path Path where to search for the Vagrantfile
    # @return [Array]
    def find_and_load_vagrantfile(path)
      vagrantfile = path
      vagrantfile = find_vagrantfile(path) if !File.file?(vagrantfile)
      return nil if !vagrantfile

      @logger.debug("Loading configuration from: #{vagrantfile.to_s}")
      config_proc = Config::ProcLoader.new.load(vagrantfile)
      result = load_config_from_procs(config_proc)
      @logger.debug(result.inspect)
      result
    end

    # Loads configuration from a single proc for the given configuration version
    # and returns it.
    #
    # @param [String] version Version of the configuration proc.
    # @param [Proc] config_proc Configuration proc.
    # @return [Hash]
    def load_config_from_procs(procs)
      # For now we assume version 1 configuration. This will need to be changed
      # in the future when we support multiple verions.
      loader = OmniConfig.new(Config::Structure.new(Config::V1::Structure.new))
      procs.each do |_version, config_proc|
        loader.add_loader(Config::V1::Loader.new(config_proc))
      end
      loader.load
    end

    # Merges a set of configurations of possibly different versions into a
    # single final configuration value in the latest version possible.
    def merge_configs(structure, *configs)
      loader = OmniConfig.new(structure)
      configs.each do |config|
        if config
          loader.add_loader(OmniConfig::Loader::Hash.new(config))
        end
      end
      loader.load
    end

    # Loads the persisted VM (if it exists) for this environment.
    def load_vms!
      result = {}

      # Load all the virtual machine instances.
      config.each do |name, vm_config|
        result[name] = Vagrant::VM.new(name, self, vm_config)
      end

      result
    end

    # This sets the `@home_path` variable properly.
    #
    # @return [Pathname]
    def setup_home_path
      @home_path = Pathname.new(File.expand_path(@home_path ||
                                                 ENV["VAGRANT_HOME"] ||
                                                 DEFAULT_HOME))
      @logger.info("Home path: #{@home_path}")

      # Setup the array of necessary home directories
      dirs = [@home_path]
      dirs += HOME_SUBDIRS.collect { |subdir| @home_path.join(subdir) }

      # Go through each required directory, creating it if it doesn't exist
      dirs.each do |dir|
        next if File.directory?(dir)

        begin
          @logger.info("Creating: #{dir}")
          FileUtils.mkdir_p(dir)
        rescue Errno::EACCES
          raise Errors::HomeDirectoryNotAccessible, :home_path => @home_path.to_s
        end
      end
    end

    protected

    # This method copies the private key into the home directory if it
    # doesn't already exist.
    #
    # This must be done because `ssh` requires that the key is chmod
    # 0600, but if Vagrant is installed as a separate user, then the
    # effective uid won't be able to read the key. So the key is copied
    # to the home directory and chmod 0600.
    def copy_insecure_private_key
      if !@default_private_key_path.exist?
        @logger.info("Copying private key to home directory")
        FileUtils.cp(File.expand_path("keys/vagrant", Vagrant.source_root),
                     @default_private_key_path)
      end

      if !Util::Platform.windows?
        # On Windows, permissions don't matter as much, so don't worry
        # about doing chmod.
        if Util::FileMode.from_octal(@default_private_key_path.stat.mode) != "600"
          @logger.info("Changing permissions on private key to 0600")
          @default_private_key_path.chmod(0600)
        end
      end
    end

    # Finds the Vagrantfile in the given directory.
    #
    # @param [Pathname] path Path to search in.
    # @return [Pathname]
    def find_vagrantfile(search_path)
      @vagrantfile_name.each do |vagrantfile|
        current_path = search_path.join(vagrantfile)
        return current_path if current_path.exist?
      end

      nil
    end

    # Loads the Vagrant plugins by properly setting up RubyGems so that
    # our private gem repository is on the path.
    def load_plugins
      # Add our private gem path to the gem path and reset the paths
      # that Rubygems knows about.
      ENV["GEM_PATH"] = "#{@gems_path}:#{ENV["GEM_PATH"]}"
      ::Gem.clear_paths

      # Load the plugins
      Plugin.load!
    end
  end
end
