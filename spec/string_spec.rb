
require_relative '../lib/string'

describe String do

  context '#indent_block' do

    it 'should indent each line by the specified amount' do
      "a\nb\nc".indent_block(2).should == "  a\n  b\n  c"
    end

    it 'should indent each line with the specified characters' do
      "a\nb\nc".indent_block(2, ?-).should == "--a\n--b\n--c"
    end

  end

  context '#autocomplete' do

    it 'should complete the string according to the list elements' do
      'ab'.autocomplete(*%w{ defgh abcdef }).should == [ :abcdef ]
    end

    it 'should complete the first characters of the words separated by - in the list elements' do
      'ad'.autocomplete(*%w{ azerty abc-def }).should == [ :'abc-def' ]
    end

  end

end
