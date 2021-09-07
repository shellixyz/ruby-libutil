
require 'test/unit'
require 'lib/colorize'

class TestColorize < Test::Unit::TestCase

  TermColor.enable

  def factor_string
    singles = 4
    factors = [ 1, 2, 3 ]
    singles.color(:singles) + ' + ' + factors.color(:factors).join(' + ')
  end

  def test_colorizer_block_value
    text = nil
    assert_nothing_raised do
      text = colorizer do |colorize|
	colorize.factors do |factor, factors|
	  factors.length > 1 ? :red : :blue
	end
	colorize.singles :green
	factor_string
      end
    end
    assert_equal "\e[32m4\e[0m + \e[31m1\e[0m + \e[31m2\e[0m + \e[31m3\e[0m", text
  end

  def test_colorizer_arg_value
    text = nil
    assert_nothing_raised do
      text = colorizer method(:factor_string) do |colorize|
	colorize.factors do |factor, factors|
	  factors.length > 1 ? :red : :blue
	end
	colorize.singles :green
      end
    end
    assert_equal "\e[32m4\e[0m + \e[31m1\e[0m + \e[31m2\e[0m + \e[31m3\e[0m", text
  end

end
