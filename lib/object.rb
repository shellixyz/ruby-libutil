
class Object

  def kind_any_of? *classes
    classes.any? { |klass| is_a? klass }
  end

end

# vim: foldmethod=syntax
