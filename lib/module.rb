
require_relative 'meta_class'

class Module

  def include_in *classes
    classes.each { |klass| klass.send :include, self }
  end

end


module Module::MetaIncludeIfExtend

  def extended dst_obj
    dst_obj.meta_include self
  end

end
