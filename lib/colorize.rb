
require 'lib/term_color'
require 'lib/module'
require 'lib/object'
require 'pp'

module Colorizer

  # Calls by colorize block to define the colors associated to names
  module Colorize
    
    # name -> color or name -> block that return a color
    @colors = {}

    def self.colors
      @colors
    end

    def self.method_missing method, *args, &block
      if block_given?
	raise ArgumentError unless args.empty?
	@colors[method] = block
      else
	raise ArgumentError if block_given? or args.length > 1 or not args.first.is_a? Symbol
	@colors[method] = args.first
      end
      nil
    end

  end

  module ColorDefinition

    # define a colorizable block named <name>
    def color_block name, *args
      color_value name, yield, *args
    end

    # define a colorizable <value> named <name>
    def color_value name, value, *args
      if value.is_a? Array
	color_array name, value, *args
      else
	color = Colorize.colors[name]
	if color
	  case
	  when color.is_a?(Symbol)
	    TermColor.send color, value.to_s
	  when color.is_a?(Proc)
	    TermColor.send color.call(value, *args), value.to_s
	  else
	    raise "unsupported color type: #{color.class}"
	  end
	else
	  value.to_s
	end
      end
    end

    # define a colorizable <array> named <name>
    def color_array name, array, *args
      array.map { |x| color_value name, x, array, *args }
    end

    # define a colorizable <array> providing index for each elements to coloring block
    def color_array_with_index name, array, *args
      array.map_with_index { |x, index| color_value name, x, array, index, *args }
    end

  end

  module ColorExecution

    # setup colors or colorize <to_colorize> or the result of the given block
    def colorize *args
      to_colorize = args.shift if args.first.kind_any_of? Proc, Method
      colors = args.shift
      raise ArgumentError, "too many arguments: #{args.length}" unless args.empty?
      old_colors = Colorize.colors.clone if block_given?
      Colorize.colors.update colors
      colorized = yield if block_given?
      (to_colorize ? to_colorize.call : colorized).tap { Colorize.colors.clear if block_given? or to_colorize }
    end

    # define colors by block and colorize <to_colorize> or the result of the block if colorizable
    def colorizer to_colorize = nil, &block
      colorized = yield Colorize
      colorized = to_colorize.call if to_colorize
      (to_colorize ? to_colorize.call : colorized).tap { Colorize.colors.clear }
    end

  end

  module ClassExtension

    def color name, *args
      color_value name, self, *args
    end

    #  include_in Symbol, String, Array, Integer, Float
    include_in Object

  end

  include ColorDefinition
  include ColorExecution

end

class Object

  include Colorizer

end

class Array

  def color_with_index name, *args
    color_array_with_index name, self, *args
  end

end

##########################################

def factor_string
  singles = 4
  factors = [ 1, 2, 3 ]
  singles.color(:singles) + ' + ' + factors.color(:factors).join(' + ')
end

# TODO: text transformer (anchors)
# TODO: unitiliser binding pour recuperer les variables locales: ex: binding.color(:singles)
# TODO: String prefix suffix avec support de nil
# TODO: String surround: ex: 'abc'.surround :braces == '(abc)'
# TODO: String surround: ex: 'abc'.surround '()' == '(abc)'
# TODO: String surround: ex: nil.surround '()' == nil


TermColor.enable

#puts colorize(method(:factor_string), :factors => :yellow, :singles => :green)

text = colorize(:factors => :yellow, :singles => :green) { factor_string }
puts text

#text = colorizer method(:factor_string) do |colorize|
#  colorize.factors do |factor, factors|
#    factors.length > 1 ? :red : :blue
#  end
#  colorize.singles :green
#end

#text = colorizer do |colorize|
#  colorize.factors do |factor, factors|
#    factors.length > 1 ? :red : :blue
#  end
#  colorize.singles :green
#  factor_string
#end

#pp text
#puts text

# vim: foldmethod=syntax
