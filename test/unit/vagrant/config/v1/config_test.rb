require File.expand_path("../../../../base", __FILE__)

require "vagrant/config/v1/config"

describe Vagrant::Config::V1::Config do
  let(:instance) { described_class.new }

  it "has a VagrantConfig object" do
    instance.vagrant.should be_kind_of(Vagrant::Config::V1::VagrantConfig)
  end

  it "has a VMConfig object" do
    instance.vm.should be_kind_of(Vagrant::Config::V1::VMConfig)
  end
end

describe Vagrant::Config::V1::VagrantConfig do
  let(:instance) { described_class.new }

  it "converts to the proper internal structure" do
    instance.dotfile_name = "foo"
    instance.host = "bar"

    instance.to_internal_structure.should == {
      "dotfile_name" => "foo",
      "host"         => "bar"
    }
  end
end

describe Vagrant::Config::V1::VMConfig do
  let(:instance) { described_class.new }

  it "converts to a proper flat structure" do
    instance.box = "foo"
    instance.box_url = "bar"

    instance.to_internal_structure_flat.should == {
      "box"     => "foo",
      "box_url" => "bar",
      "name"    => nil,
      "primary" => nil
    }
  end

  it "converts a single VM to a proper internal structure" do
    instance.box = "foo"
    instance.box_url = "bar"

    instance.to_internal_structure.should == [instance.to_internal_structure_flat]
  end

  it "should convert multiple VMs into a proper internal structure" do
    instance.define("foo")
    instance.define("bar")

    result = instance.to_internal_structure
    result.length.should == 2
    result[0]["name"].should == "foo"
    result[1]["name"].should == "bar"
  end

  it "should properly inherit parent settings for a sub-VM" do
    instance.box = "foo"
    instance.define("subvm")

    result = instance.to_internal_structure
    result.length.should == 1
    result[0]["name"].should == "subvm"
    result[0]["box"].should == "foo"
  end
end
