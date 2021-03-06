
class Numeric

  def self.commify n
      n.to_s =~ /([^\.]*)(\..*)?/
      int, dec = $1.reverse, $2 ? $2 : ""
      while int.gsub!(/(,|\.|^)(\d{3})(\d)/, '\1\2,\3')
      end
      int.reverse + dec
  end

  def commify
    Numeric.commify self
  end

end
