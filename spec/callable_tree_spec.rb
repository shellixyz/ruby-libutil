
require_relative '../lib/callable_tree'

describe CallableTree do

  let(:ct) { CallableTree.new }

  it "#['a/b/c']=value should build a tree of CallableHashes like that: {:a => {:b => {:c => value}}}" do
    ct['a/b/c'] = :value
    ct.should == {:a => {:b => {:c => :value}}}
  end

  it "#['a/b/c'] should be equivalent to #[:a][:b][:c] but raising errors if a value is encountered in path or a node doesnt exist" do
    ct['a/b/c'] = :value
    ct['a/b/c'].should == :value
    expect { ct['a/b/c/d'] }.to raise_error(CallableTree::Error::InvalidKey)
    expect { ct['a/c/e'] }.to raise_error(CallableTree::Error::InvalidKey)
  end

end
