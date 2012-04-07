module Vagrant
  module Config
    # Allows accessing a hash using method dispatch. An example makes
    # this clear:
    #
    # ```ruby
    # hash    = { "key" => 7 }
    # wrapped = HashWrapper.new(hash)
    # p wrapped.key # => 7
    # ```
    #
    # While I'm not specifically a fan of this, this was mostly created
    # as a way to maintain backwards code compatibility with how configuration
    # used to be references (as objects with attributes). Currently all
    # configuration is represented internally as a Hash.
    #
    # Perhaps in the future this will be deprecated.
    class HashWrapper
      def initialize(hash)
        @hash = hash
      end

      def method_missing(meth, *args, &block)
        key = meth.to_s
        if @hash.has_key?(key)
          # Return the value in the hash, but make sure to properly wrap
          # it again if the value is a Hash.
          value = @hash[key]
          return value if !value.is_a?(Hash)
          return self.class.new(value)
        end

        super
      end
    end
  end
end
