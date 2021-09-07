
class Object

  def meta_class
    class << self; self; end
  end

  def meta_def name, &blk
    meta_class.instance_eval { define_method name, &blk }
  end

  def meta_include *modules
    meta_class.send :include, *modules
  end

  def meta_include? module_arg
    meta_class.include? module_arg
  end

  def obj_include? module_arg
    self.class.include? module_arg or meta_class.include? module_arg
  end

  def extend_unless_include *modules
    meta = meta_class
    modules.each { |m| extend m unless self.class.include? m or meta.include? m }
    self
  end

end
