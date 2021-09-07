
require_relative 'caller'

module Kernel

  # require all files with extension .rb in relative directory <dir>
  def require_dir_relative dir
    dir = File.join direct_caller_source_dir, dir
    Dir.glob("#{dir}/*.rb").each { |file| require file }
  end

  def try_require_relative path
    require File.join(direct_caller_source_dir, path)
  rescue LoadError
    yield path if block_given?
  end

  def try_require path
    require path
  rescue LoadError
    yield path if block_given?
  end

end

# vim: foldmethod=syntax
