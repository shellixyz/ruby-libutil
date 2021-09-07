
class String

  # indent all lines in string with level*str
  def indent_block(level=2, str = ' ')
    indent = str * level
    split("\n").map { |line| indent + line }.join("\n")
  end

  # autocomplete string with the help of the list
  # "ab".autocomplete("abc", "bcd", "atc-bef") = "atc-bef"
  # "abc".autocomplete("abcd", "bcd", "abc-cef") = "abcd"
  # "b".autocomplete("abcd", "bcd", "abc-cef") = "bcd"
  def autocomplete(*list)
    word = self
    exact_match = false
    matchs = list.find_all do |lword|
      lword = lword.to_s
      if lword == word then
	exact_match = true
	break
      end
      if lword[0...word.length] == word then
	true
      else
	shortcut = lword.split('-').map { |part| part[0].chr }.join
	shortcut[0...word.length] == word
      end
    end
    if exact_match then
      [ word.to_sym ]
    else
      matchs.map { |m| m.to_sym }
    end
  end

  # return all the elements
  def relative_path path
    path += '/' unless path[-1] == ?/
    raise ArgumentError, "#{self} does not begin with #{path}" if self[0...path.length] != path
    self[path.length..-1]
  end

  def basename
    File.basename self
  end

  def prefix(prefix)
    prefix + self
  end

  def postfix(suffix)
    self + postfix
  end

  def integer?
    #not match(/\A[+-]?\d+\Z/).nil?
    true if Integer self rescue false # could be relatively slow
  end

  def float?
    #not match(/\A[+-]?\d+(\.\d+)?\Z/).nil?
    true if Float self rescue false # could be relatively slow
  end

  def to_i_if_possible
    Integer self
  rescue ArgumentError
    self
  end

  def to_f_if_possible
    Float self
  rescue ArgumentError
    self
  end

  def to_numeric_if_possible
    case
    when integer?; to_i
    when float?; to_f
    else self
    end
  end

  def to_integer
    Integer self
  end

  def to_float
    Float self
  end

  def to_numeric
    case
    when integer?; to_i
    when float?; to_f
    else
      raise ArgumentError, "invalid value for Integer(): #{inspect}"
    end
  end

  alias :auto_convert :to_numeric
  alias :to_n :to_numeric

  def surround by_s
    by_s_def = { :braces => '()', :brackets => '[]', :cbrackets => '{}' }
    by_s = by_s_def[by_s] if by_s.is_a? Symbol
    by_s = by_s.chr if by_s.is_a? Fixnum
    raise ArgumentError if by_s.nil? or by_s.length > 2
    by_s.length == 1 ? by_s + self + by_s : by_s[0].chr + self + by_s[1].chr
  end

  def snake_case
    gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
      gsub(/([a-z])([A-Z])/, '\1_\2').
	downcase
  end

  def camel_case
    split('_').map{|e| e.capitalize}.join
  end

end

class NilClass

  def to_i_if_possible
    self
  end

  def to_f_if_possible
    self
  end

end

# vim: foldmethod=syntax
