require "log4r"

module Vagrant
  module Config
    # This class is responsible for loading configuration procs out
    # of Vagrantfiles. Configuration files run `Vagrant.configure`
    # and send it a proc that handles configuration. This will capture
    # those procs and return them.
    class ProcLoader
      def initialize
        @logger = Log4r::Logger.new("vagrant::config::procloader")
      end

      # Load the procs from the given file.
      #
      # @param [String] path Path to a Ruby file that may contain procs.
      # @return [Array] Array of tuples in the format of `[version, block]`.
      def load(path)
        @logger.debug("Loading procs for path: #{path}")

        begin
          return Config.capture_configures { Kernel.load(path) }
        rescue SyntaxError => e
          # Report syntax errors in a nice way.
          raise Errors::VagrantfileSyntaxError, :file => e.message
        end
      end
    end
  end
end
