
require 'binding_of_caller'

class Binding

  def source_file
    eval '__FILE__'
  end

  def source_file_short
    source_file.start_with?(Dir.pwd) ? source_file[Dir.pwd.length..-1] : source_file
  end

  def source_line
    eval '__LINE__'
  end

  def source_location
    "#{source_file}:#{source_line}"
  end

  def source_location_short
    "#{source_file_short}:#{source_line}"
  end

  def source_module
    eval 'is_a?(Class) || is_a?(Module) ? self : self.class'
  end

  def source_object
    eval 'self'
  end

  def method_name
    frame_description[/\A(?:block in )?(.+)\Z/, 1]
  end

  def method_full
    "#{source_module}.#{method_name}"
  end

  def caller
    of_caller 2
  end

end
