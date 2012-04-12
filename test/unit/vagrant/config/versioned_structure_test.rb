require File.expand_path("../../../base", __FILE__)

require "omniconfig"

describe Vagrant::Config::VersionedStructure do
  include_context "unit"

  let(:instance)    do
    described_class.new(env, version,
                        :version_registry => versions,
                        :keys_registry    => config_keys)
  end

  let(:config_keys) { Vagrant::Registry.new }
  let(:env)         { Object.new }
  let(:version)     { "1" }
  let(:versions)    { Vagrant::Registry.new }
  let(:version_class) do
    Class.new do
      def config_keys; {} end
    end
  end

  before(:each) do
    versions.register("1") { version_class.new }
  end

  it "should always have an 'id' field" do
    instance.members.should have_key("id")
    instance.members["id"].should be_kind_of(OmniConfig::Type::String)
  end

  it "should properly add members from the config version specified" do
    version_class = Class.new do
      attr_reader :foo_type
      attr_reader :bar_type

      def initialize
        base_type = Class.new(OmniConfig::Type::Base) do
          attr_reader :env

          def initialize(env)
            @env = env
          end
        end

        @foo_type = Class.new(base_type)
        @bar_type = Class.new(base_type)
      end

      def config_keys
        {
          "foo" => @foo_type,
          "bar" => @bar_type
        }
      end
    end

    # Instantiate the version and register it as our version
    version_class = version_class.new
    versions.register(version) { version_class }

    # Verify that our instance is setup properly
    instance.members.should have_key("foo")
    instance.members["foo"].should be_kind_of(version_class.foo_type)
    instance.members["foo"].env.should eql(env)

    instance.members.should have_key("bar")
    instance.members["bar"].should be_kind_of(version_class.bar_type)
    instance.members["bar"].env.should eql(env)
  end

  it "should add members from the configured config keys" do
    base_type = Class.new(OmniConfig::Type::Base) do
      attr_reader :env

      def initialize(env)
        @env = env
      end
    end

    foo_type = Class.new(base_type)
    bar_type = Class.new(base_type)

    # Register a couple config keys
    config_keys.register("foo") { foo_type }
    config_keys.register("bar") { bar_type }

    # Verify the config keys are available on our instance
    instance.members.should have_key("foo")
    instance.members["foo"].should be_kind_of(foo_type)
    instance.members["foo"].env.should eql(env)

    instance.members.should have_key("bar")
    instance.members["bar"].should be_kind_of(bar_type)
    instance.members["bar"].env.should eql(env)
  end
end
