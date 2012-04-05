require File.expand_path("../../../../base", __FILE__)

require "vagrant/config/v1/config"

describe Vagrant::Config::V1::Loader do
  it "should run the proc and return the data properly" do
    config_proc = Proc.new do |config|
      config.vm.box = "foo"
    end

    expected = Vagrant::Config::V1::Config.new
    config_proc.call(expected)

    loader = described_class.new(config_proc)
    loader.load(nil).should == expected.to_internal_structure
  end
end
