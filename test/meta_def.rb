#!/usr/bin/ruby

require 'lib/meta_def'
require 'test/unit'

class TestMetaDef < Test::Unit::TestCase

  module X_1

    class Y_1

      def self.y
	'xhellox'
      end

    end

  end

  def test_1

    assert_nothing_raised do
      X_1.module_eval { meta_def :x, &X_1::Y_1.method(:y) }
    end

    x = nil
    assert_nothing_raised do
      x = X_1.x
    end

    assert_equal 'xhellox', x
  end

  module X_2; end

  def test_2
    assert_nothing_raised do
      X_2.module_eval { meta_def(:x) { "xhellox" } }
    end

    x = nil
    assert_nothing_raised do
      x = X_2.x
    end

    assert_equal 'xhellox', x
  end

  class X_3; end

  def test_3
    x = X_3.new
    assert_nothing_raised do
      x.meta_def(:x) { 'xhellox' }
    end

    assert_equal 'xhellox', x.x
  end

end

# vim: foldmethod=syntax
