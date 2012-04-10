require File.expand_path("../../../../base", __FILE__)

require "omniconfig"

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

    result = instance.to_internal_structure_flat
    result["box"].should == "foo"
    result["box_url"].should == "bar"
    result["name"].should == OmniConfig::UNSET_VALUE
  end

  describe "to_internal_structure_vms" do
    it "returns an empty list of VMs if there are none" do
      instance.to_internal_structure_vms.should be_empty
    end

    it "returns an array of defined sub-VMs" do
      instance.define :foo
      instance.define :bar

      result = instance.to_internal_structure_vms
      result.length.should == 2
      result[0]["vm"]["name"].should == "foo"
      result[1]["vm"]["name"].should == "bar"
    end
  end
end
