
class Numeric

  def clip args
    num = self
    num = args[:min] if args.has_key? :min and num < args[:min]
    num = args[:max] if args.has_key? :max and num > args[:max]
    return num
  end

end
