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

  it "converts a single VM to a proper internal structure" do
    instance.box = "foo"
    instance.box_url = "bar"

    instance.to_internal_structure.should == {
      "box"     => "foo",
      "box_url" => "bar",
      "name"    => nil
    }
  end
end
