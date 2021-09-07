
class TermColor

  def self.enable
    require 'rubygems'
    begin
      require 'term/ansicolor'
      @enabled = true
    rescue LoadError
      @enabled = false
      return false
    end
    true
  end

  def self.disable
    self.color = false
  end

  def self.color?
    @enabled
  end

  def self.color= status
    @enabled = status
  end

  def self.enabled?
    @enabled == true
  end

  def self.attributes
    enabled? ? Term::ANSIColor.attributes : []
  end

  def self.surround text, by_s, color
    by_s_def = { :braces => '()', :brackets => '[]', :cbrackets => '{}' }
    by_s = by_s_def[by_s] if by_s.is_a? Symbol
    by_s = by_s.chr if by_s.is_a? Fixnum
    raise ArgumentError if by_s.nil? or by_s.length > 2
    by_s.length == 1 ? send(color, by_s) + text + send(color, by_s) : send(color, by_s[0].chr) + text + send(color, by_s[1].chr)
  end

  def self.method_missing(symbol, *args)
    raise ArgumentError, 'block and args given' if block_given? and not args.empty?
    raise ArgumentError, "too many arguments: #{args.length}" if args.length > 1
    value = block_given? ? yield : args.first
    return nil if value.nil? and not args.empty?
    if enabled?
      bold, color = symbol.to_s.match(/\A(bold_)?(\w+)\Z/).captures
      if value.nil?
	value = Term::ANSIColor.send color
	value = Term::ANSIColor.bold + value if bold
      else
	value = Term::ANSIColor.send color, value
	value = Term::ANSIColor.bold value if bold
      end
    else
      value = '' if value.nil?
    end
    return value
  end

end

# vim: foldmethod=syntax
