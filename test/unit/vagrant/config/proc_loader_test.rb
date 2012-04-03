require File.expand_path("../../../base", __FILE__)

describe Vagrant::Config::ProcLoader do
  include_context "unit"

  let(:instance) { described_class.new }

  it "should return the set of procs loaded" do
    result = instance.load(temporary_file(<<-CONTENTS))
Vagrant.configure("1") do |block|
  $_config_data << "ONE"
end

Vagrant.configure("2") do |block|
  $_config_data << "TWO"
end
CONTENTS

    # Reset this so that we can run the procs
    $_config_data = []

    # Verify that the data we got back is valid
    result.length.should == 2
    result.map { |r| r[0] }.should == ["1", "2"]
    result.each { |r| r[1].call(nil) }
    $_config_data.should == ["ONE", "TWO"]
  end

  it "should raise a proper error if there is a syntax error" do
    expect { instance.load(temporary_file("Vagrant:^Config")) }.
      to raise_error(Vagrant::Errors::VagrantfileSyntaxError)
  end
end
