
require_relative 'string'

class Symbol

  def +(s1)
    (self.to_s + s1.to_s).to_sym
  end

#  def begin_with?(arg)
#    to_s.begin_with? arg.to_s
#  end
# because String.start_with already in corelib: replaced by ->
  def start_with?(arg)
    to_s.start_with? arg.to_s
  end

  def end_with?(arg)
    to_s.end_with? arg.to_s
  end

end

# vim: foldmethod=syntax
