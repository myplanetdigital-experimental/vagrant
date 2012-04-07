require File.expand_path("../../../base", __FILE__)

describe Vagrant::Config::HashWrapper do
  include_context "unit"

  it "should provide attribute access to a hash" do
    hash    = { "key" => 7 }
    wrapped = described_class.new(hash)
    wrapped.key.should == 7
  end

  it "should raise NoMethodErrors for invalid keys" do
    wrapped = described_class.new({})
    expect { wrapped.key }.
      to raise_error(NoMethodError)
  end

  it "should wrap nested hashes" do
    hash = { "key" => { "foo" => 8 } }
    wrapped = described_class.new(hash)
    wrapped.key.foo.should == 8
  end
end
