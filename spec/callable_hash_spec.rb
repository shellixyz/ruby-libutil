
require_relative '../lib/callable_hash'

describe CallableHash do

  let(:ch) { CallableHash.new }

  it "#key= should be equivalent to #[key]=" do
    ch.testkey = :testvalue
    ch.other_key = :other_value
    ch[:testkey].should == :testvalue
    ch[:other_key].should == :other_value
    ch[:undef_key].should be_nil
  end

  it "#key should be equivalent to #[key]" do
    ch[:test_key] = :testvalue
    ch[:other_key] = :other_value
    ch.test_key.should == :testvalue
    ch.other_key.should == :other_value
  end

  it "#key should be equivalent to #key but if the key doesnt exists raises an error" do
    ch[:test_key] = :testvalue
    ch[:other_key] = :other_value
    ch.test_key!.should == :testvalue
    ch.other_key!.should == :other_value
    expect { ch.undef_key! }.to raise_error(ArgumentError)
  end

end
