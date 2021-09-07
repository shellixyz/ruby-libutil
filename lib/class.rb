
class Class

  def superclasses
    schain = []
    sclass = superclass
    while sclass != Object
      schain << sclass
      sclass = sclass.superclass
    end
    schain.reverse
  end

end

# vim: foldmethod=syntax
