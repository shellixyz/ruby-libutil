
module IncludeOnce

  def include_once *modules
    modules.each { |m| include m unless include? m }
  end

end

class Module

  include IncludeOnce

end

class Class

  include IncludeOnce

end

# vim: foldmethod=syntax
