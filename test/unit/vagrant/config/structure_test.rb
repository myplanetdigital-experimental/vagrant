require File.expand_path("../../../base", __FILE__)

describe Vagrant::Config::Structure do
  include_context "unit"

  let(:instance) { described_class.new(versioned_struct) }
  let(:versioned_struct) {
    OmniConfig::Structure.new do |s|
      s.define("id", OmniConfig::Type::String)
      s.define("key", OmniConfig::Type::Any)
      s.define("key2", OmniConfig::Type::Any)
    end
  }

  it "should merge properly" do
    old = {
      "global" => { "key" => "foo" },
      "vms"    => []
    }

    new = {
      "global" => { "key" => "bar" },
      "vms"    => []
    }

    result = instance.merge(old, new)
    result["global"]["key"].should == "bar"
    result["vms"].should be_empty
  end

  it "should merge VMs by ID" do
    old = {
      "global" => {},
      "vms"    => [
        { "id" => "foo", "key2" => "foovalue" }
      ]
    }

    new = {
      "global" => {},
      "vms"    => [
        { "id" => "foo", "key" => "barvalue" }
      ]
    }

    result = instance.merge(old, new)
    result["vms"].length.should == 1
    vm = result["vms"][0]
    vm["id"].should == "foo"
    vm["key"].should == "barvalue"
    vm["key2"].should == "foovalue"
  end

  it "should order the VM merge properly" do
    old = {
      "global" => {},
      "vms"    => [
        { "id" => "foo" },
        { "id" => "bar" }
      ]
    }

    new = {
      "global" => {},
      "vms"    => [
        { "id" => "foo" },
        { "id" => "baz" }
      ]
    }

    result = instance.merge(old, new)
    result["vms"].length.should == 3
    ids = result["vms"].map { |vm| vm["id"] }
    ids.should == ["foo", "bar", "baz"]
  end
end
