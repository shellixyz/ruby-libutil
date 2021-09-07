
require_relative '../lib/callbacks'

describe Callbacks::SmartCallback, "basic operation" do

  it "should #call the given object with the iterator himself calling the block specified with iterator args and specified args" do
    sample_args = [ 1, 2, 3 ]
    block = proc { |x| x + 1 }
    scb = Callbacks::SmartCallback.new(:map, &block)
    scb.call(sample_args).should == sample_args.map(&block)
  end

  it "#call should pass given args to the block" do
    sample_args = [ 1, 2, 3 ]
    block = proc { |x, n| x + n }
    scb = Callbacks::SmartCallback.new(:map, &block)
    scb.call(sample_args, 2).should == sample_args.map { |x| x + 2 }
  end

end

describe Callbacks::Sequence, "basic operation" do

  it "should #call callbacks in sequence" do
    cbs0 = Callbacks::Sequence.new
    cbs0 << proc { |*args| args << :block0 } # arguments to call are passed to the first block
    cbs0 << proc { |*args| args << :block1 } # what is returned from the first block is passed as argument to the next one
    cbs0.call(:arg).should == [ :arg, :block0, :block1 ]

    cbs1 = Callbacks::Sequence.new
    cbs1 << proc { |str| 'Hello ' + str }
    cbs1 << proc { |str| str + ' world' }
    cbs1.call('wonderful').should == 'Hello wonderful world'
  end

  it "#vcall should call callbacks in sequence appending args to each block result to call the next callback" do
    cbs = Callbacks::Sequence.new
    cbs << proc { |value, *args| args[0] + value + args[1] }
    cbs << proc { |value, *args| args[1] + value + args[0] }
    cbs.vcall(%w{ * ! }, 'hello').should == '!*hello!*'
  end

  it "#vcall can be called with multiple values" do
    cbs = Callbacks::Sequence.new
    cbs << proc { |v0, v1, *args| [ v0 + 2 * args[0], v1 - 2 * args[1] ] } # 0 + 2 * 2 = 4; 1 - 2 * 4 = -7
    cbs << proc { |v0, v1, *args| [ v0 - 4, v1 + 3 * args[0] ] }           # 4 - 4 = 0; -7 + 3 * 2 = -1
    cbs.vcall([2, 4], 0, 1).should == [0, -1]
  end

end

describe Callbacks::Hash, "basic operation" do

  let(:cbh) { Callbacks::Hash.new }

  it "should allow to #define a callback with a block" do
    sample_args = [ :s0, :sample1 ]
    block0 = proc { |*args| args << :block0 }
    block1 = proc { |*args| args << :block1 }

    cbh.define :name0, &block0
    cbh.define :name1, &block1
    cbh[:name0].call(*sample_args).should == sample_args.clone << :block0
    cbh[:name1].call(*sample_args).should == sample_args.clone << :block1
  end

  it "should be able to redefine a callback with #define!" do
    sample_args = [ :s0, :sample1 ]
    block0 = proc { |*args| args << :block0 }
    block1 = proc { |*args| args << :block1 }

    cbh.define! :name, &block0
    cbh.define! :name, &block1
    cbh[:name].call(*sample_args).should == sample_args << :block1
  end

  it "should allow to test if a callback is defined with #defined?" do
    cbh.define(:name) { do_something }
    cbh.defined?(:name).should be_true
    cbh.defined?(:undef).should be_false
  end

  it "should allow to #undef a callback" do
    cbh.define(:name) { do_something }
    undef0_return = cbh.undef :name         # raise an error if name is not defined
    undef1_return = cbh.undef! :notdefined   # no error raised if name is not defined

    cbh[:name].should be_nil
    [ undef0_return, undef1_return ].should === [ cbh, cbh]
  end

  it "should allow to #add multiple callbacks for a name" do
    block0 = proc { do_something }
    block1 = proc { do_something_else }
    cbh.add :name, &block0
    cbh.add :name, &block1
    cbh[:name].should == [ block0, block1 ]
  end

  it "should transform a simple Callback to a Sequence if #add(name) is used after #define(name)" do
    block0 = proc { do_something }
    block1 = proc { do_something_else }
    cbh.define :name, &block0
    cbh.add :name, &block1
    cbh[:name].should == [ block0, block1 ]
  end

  it "should call callbacks in sequence when multiple callbacks has been defined for a name" do
    cbh.add(:name0) { |*args| args << :block0 }
    cbh.add(:name0) { |*args| args << :block1 }
    cbh[:name0].call(:arg).should == [ :arg, :block0, :block1 ]

    cbh.add(:name1) { |str| 'Hello ' + str }
    cbh.add(:name1) { |str| str + ' world' }
    cbh[:name1].call('wonderful').should == 'Hello wonderful world'
  end

  it "#define_smart should #define a SmartCallback" do
    sample_args = [ 1, 2, 3 ]
    block = proc { |x| x + 1 }
    cbh.define_smart(:name, :map, &block)
    cbh[:name].call(sample_args).should == sample_args.map(&block)
  end

  it "#add_smart should #add a SmartCallback" do
    sample_collection = [ 1, 2, 3 ]
    block0 = proc { |x| x + 1 }
    block1 = proc { |x| x + 2 }
    cbh.add_smart(:name, :map, &block0)
    cbh.add_smart(:name, :map, &block1)
    cbh[:name].call(sample_collection).should == sample_collection.map(&block0).map(&block1)
  end

  it "#call should forget the callback result value when defined with :keep_result => false" do
    sample_args = [ 1, 2, 3 ]
    cbh.define(:test, :keep_result => false) { :return_something }
    cbh[:test].call(sample_args).should == sample_args
  end

  it "should define a smart callback when #define or #add are called with non nil :iterator option" do
    cbh.define(:name0, :iterator => nil) { do_something }
    cbh.add(:name0, :iterator => nil) { do_something }
    cbh.define(:name1, :iterator => :map) { do_something }
    cbh.add(:name1, :iterator => :map) { do_something }
    cbh[:name0].all? { |cb| cb.should be_an_instance_of(Proc) }
    cbh[:name1].all? { |cb| cb.should be_an_instance_of(Callbacks::SmartCallback) }
  end

  it "should create a normal callback when #define_smart or #add_smart are called with nil iterator" do
    cbh.define_smart(:name0, nil) { do_something }
    cbh.add_smart(:name0, nil) { do_something }
    cbh.define_smart(:name1, :map) { do_something }
    cbh.add_smart(:name1, :map) { do_something }
    cbh[:name0].all? { |cb| cb.should be_an_instance_of(Proc) }
    cbh[:name1].all? { |cb| cb.should be_an_instance_of(Callbacks::SmartCallback) }
  end

  it "should allow to call vcall on any type of callback when options (or false) are passed to define functions or #force_proc_conversion" do
    cbh.define(:name0, false) { 'standard callback with false as options' }
    cbh.define(:name1, :someoption => :somevalue) { 'standard callback with options' }
    cbh.force_proc_convertion = true
    cbh.define(:name2) { 'standard callback' }
    cbh.add(:name3) { 'sequence callback 0' }
    cbh.add(:name3) { 'sequence callback 1' }
    cbh.define_smart(:name4, :each) { 'smart callback' }
    cbh.add_smart(:name5, :each) { 'sequence smart callback 0' }
    cbh.add_smart(:name5, :each) { 'sequence smart callback 1' }
    expect {
      cbh[:name0].vcall
      cbh[:name1].vcall
      cbh[:name2].vcall
      cbh[:name3].vcall
      cbh[:name4].vcall nil, []
      cbh[:name5].vcall nil, []
      cbh[:name5].vcall nil, []
    }.not_to raise_error
  end

  it "#call_chain should return arguments if called name is undefined" do
    cbh.call_chain(:undefined_name, :arg).should == :arg
    cbh.call_chain(:undefined_name, :arg0, :arg1).should == [ :arg0, :arg1 ]
  end

  it "#vcall_chain should return values passed as argument if called name is undefined" do
    cbh.vcall_chain(:undefined_name, [:arg0, :arg1], :value).should == :value
    cbh.vcall_chain(:undefined_name, [:arg0, :arg1], :value1, :value2).should == [ :value1, :value2 ]
  end

end

describe Callbacks::Hash, "error handling" do

  let(:cbh) { Callbacks::Hash.new }

  it "should fail if define or add is called without a block" do
    expect { cbh.define :name }.to raise_error(ArgumentError)
    expect { cbh.add :name }.to raise_error(ArgumentError)
  end

  it "should fail if a callback is redefined with #define or #define_smart" do
    expect {
      cbh.define :name
      cbh.define :name
    }.to raise_error(ArgumentError)

    expect {
      cbh.define_smart :name
      cbh.define_smart :name
    }.to raise_error(ArgumentError)
  end

  it "should fail if #undef is called without the callback being defined" do
    cbh.undef! :undefined
    expect { cbh.undef :name }.to raise_error(ArgumentError)
  end

  it "should raise an error if #call on an undefined name" do
    expect { cbh.call :undefined }.to raise_error(Callbacks::Hash::Error::UndefinedName)
    expect { cbh.vcall :undefined }.to raise_error(Callbacks::Hash::Error::UndefinedName)
    expect { cbh.call_if_defined :undefined }.not_to raise_error
    expect { cbh.vcall_if_defined :undefined }.not_to raise_error
    cbh.call_if_defined(:undefined).should be_nil
    cbh.vcall_if_defined(:undefined).should be_nil
  end

end
