
require 'lib/term_color'
require 'lib/string'

class ZshColor

  def self.colorize str, color
    '%{' + TermColor.send(color) + '%}' + str + '%{' + TermColor.reset + '%}'
  end

  def self.method_missing(symbol, *args)
    raise ArgumentError, 'block and args given' if block_given? and not args.empty?
    raise ArgumentError, "too many arguments: #{args.length}" if args.length > 1
    value = block_given? ? yield : args.first
    return nil if value.nil? and not args.empty?
    if TermColor.enabled?
      bold, color = symbol.to_s.match(/\A(bold_)?(\w+)\Z/).captures
      if value.nil?
				value = '%{' + TermColor.send(color) + '%}'
				value = TermColor.bold + value if bold
				value = '%{' + value + '%}'
			else
				value = colorize value, color
				value = colorize value, :bold if bold
			end
		else
			value = '' if value.nil?
    end
    return value
  end

  def self.surround text, by_s, color
		if TermColor.enabled?
			by_s_def = { :braces => '()', :brackets => '[]', :cbrackets => '{}' }
			by_s = by_s_def[by_s] if by_s.is_a? Symbol
			by_s = by_s.chr if by_s.is_a? Integer
			raise ArgumentError if by_s.nil? or by_s.length > 2
			by_s.length == 1 ? colorize(by_s, color) + text + colorize(by_s, color) : colorize(by_s[0].chr, color) + text + colorize(by_s[1].chr, color)
		else
			text.surround by_s
		end
  end

end

# vim: foldmethod=syntax
