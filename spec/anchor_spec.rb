
require_relative '../lib/anchor'

def test_func
  to_sum = [ 1, 2, 3 ].anchor(:to_sum)
  factor = 5.anchor(:factor)
  to_sum.join(" #{'+'.anchor(:plus)} ") + " #{'*'.anchor(:asterisk)} " + factor.to_s
end

describe '#test_func' do

  it "outside a #anchor_catcher block should return \"1 + 2 + 3 * 5\"" do
    test_func.should == "1 + 2 + 3 * 5"
  end

end

describe Anchor, '#anchor_catcher' do

  context "called with <to_run_catch> == nil" do

    it "should yield Anchor::Catcher::Interface" do
      catcher_interface = nil
      test_func = proc {}
      anchor_catcher { |catcher_interface| }
      catcher_interface.should == Anchor::Catcher::Interface
    end

    it "should catch anchors called within the block" do
        test_args = :first_arg, :second_arg
        test_func = proc { |arg0, arg1| arg0.anchor(:arg0); arg1.anchor(:arg1) }
        captures = [ [], [] ]
        anchor_catcher do |catcher|
          catcher.capture(:arg0) { |arg0| captures[0] << arg0 }
          catcher.capture(:arg1) { |arg1| captures[1] << arg1 }
          test_func.call(*test_args)
        end
        captures.should == [ [:first_arg], [:second_arg] ]
    end

  end

  context "called with <to_run_catch> != nil" do

    it "should eval the block in module Catcher::Interface" do
      catcher_interface = nil
      test_func = proc {}
      anchor_catcher(test_func) { catcher_interface = self }
      catcher_interface.should == Anchor::Catcher::Interface
    end

    it "should first eval the associated block and then call <to_run_catch> with <*args>" do
      test_args = :first_arg, :second_arg
      calls = []
      (test_func = mock('proc')).should_receive(:call).with(*test_args).once do |arg0, arg1|
        calls << :proc
        arg0.anchor(:arg0)
        arg1.anchor(:arg1)
      end
      anchor_catcher(test_func, *test_args) { calls << :block }
      calls.should == [ :block, :proc ]
    end

    it "should catch anchors called within the block" do
      test_args = :first_arg, :second_arg
      test_func = proc { |arg0, arg1| arg0.anchor(:arg0); arg1.anchor(:arg1) }
      captures = [ [], [] ]
      anchor_catcher test_func, *test_args do
        capture(:arg0) { |arg0| captures[0] << arg0 }
        capture(:arg1) { |arg1| captures[1] << arg1 }
      end
      captures.should == [ [:first_arg], [:second_arg] ]
    end

  end

  #context 'nested blocks' do
  #end

  context 'catcher' do

    it '#capture should register a block capturing specified anchor name. block value is discarded and anchor value is not modified' do
      anchor_values = nil
      test_func = proc { anchor_values = [ :anchor0_value.anchor(:anchor0), :anchor1_value.anchor(:anchor1) ] }
      captures = [ [], [] ]
      anchor_catcher test_func do
        capture(:anchor0) { |anchor0| captures[0] << anchor0 }
        capture(:anchor1) { |anchor1| captures[1] << anchor1 }
      end
      anchor_values.should == [ :anchor0_value, :anchor1_value ]
      captures.should == [ [:anchor0_value], [:anchor1_value] ]
    end

    it '#transform should register a block capturing specified anchor name. the value returned by anchor is the value of the last block' do
      anchor_value = nil
      test_func = proc { anchor_value = :anchor_value.anchor(:anchor_name) }
      captures = []
      anchor_catcher test_func do
        transform(:anchor_name) { |anchor_value| captures << anchor_value; :other_value }
      end
      anchor_value.should == :other_value
      captures.should == [ :anchor_value ]
    end

    context '#replace' do

      it 'when called with <name> and <value> should replace anchor <name> value with <value>' do
        anchor_value = nil
        test_func = proc { anchor_value = :anchor_value.anchor(:anchor_name) }
        anchor_catcher test_func do
          replace(:anchor_name, :other_value)
        end
        anchor_value.should == :other_value
      end

      it 'when called with a Hash should replace all anchor values names after keys with hash corresponding value' do
        anchor_value = nil
        test_func = proc { anchor_value = :anchor_value.anchor(:anchor_name) }
        anchor_catcher test_func do
          replace(:anchor_name => :other_value)
        end
        anchor_value.should == :other_value
      end

    end

    context '#colorize' do

      it 'when passed a name should colorize captured anchor value with the color returned by the block' do
        anchor_value = nil
        TermColor.enable
        test_func = proc { anchor_value = 'text'.anchor(:text_anchor) }
        anchor_catcher test_func do
          colorize(:text_anchor) { :red }
        end
        anchor_value.should == TermColor.red('text')
      end

      it 'when passed an array of names should colorize captured anchor values with the color returned by the block' do
        anchor_values = nil
        TermColor.enable
        test_func = proc { anchor_values = [ 'text'.anchor(:text_anchor), 'othertext'.anchor(:othertext_anchor) ] }
        anchor_catcher test_func do
          colorize([:text_anchor, :othertext_anchor]) { :red }
        end
        anchor_values.should == [ TermColor.red('text'), TermColor.red('othertext') ]
      end

      it 'when passed a hash should colorize captures named after hash keys with color in values' do
        anchor_value = nil
        TermColor.enable
        test_func = proc { anchor_value = 'text'.anchor(:text_anchor) }
        anchor_catcher test_func do
          colorize(:text_anchor => :red)
        end
        anchor_value.should == TermColor.red('text')
      end

      it 'when passed a hash with hash as values should colorize captures named after hash keys with colors hash in values of the form value => color' do
        anchor_values = nil
        TermColor.enable
        test_func = proc { anchor_values = [ false.anchor(:anchor_name), true.anchor(:anchor_name) ] }
        anchor_catcher test_func do
          colorize(:anchor_name => { false => :red, true => :green })
        end
        anchor_values.should == [ TermColor.red(false.to_s), TermColor.green(true.to_s) ]
      end

    end

  end


  #context 'with' do
  #end

end

#describe Anchor, '#anchor_capture' do
#end

describe Anchor, '#anchor_start_end' do

  it 'should anchor nil with name "<namespace>/start" then yield then anchor nil with name "<namespace>/end"' do
    calls = []
    test_func = lambda { anchor_start_end('test_func') { calls << :yield } }
    anchor_catcher test_func do
      capture('test_func/start') { calls << :start }
      capture('test_func/end') { calls << :end }
    end
    calls.should == [ :start, :yield, :end ]
  end

end
