
require 'rubygems'
require_relative 'array'

module Path

  # simplify x/.. /./ and //
  # result end with / if input was
  def self.simplify path, dot_if_empty = true
    parts = path.split(/\/+/).reject { |pc| pc == '.' }
    new_parts = []
    parts.each do |p|
      if p == '..'
	if new_parts.empty? or new_parts.last == '..'
	  new_parts << '..'
	  return '/' if absolute? path
	else
	  new_parts.pop
	end
      else
	new_parts << p
      end
    end
    new_path = File.join new_parts
    new_path = new_path.empty? && absolute?(path) ? '/' + new_path : new_path
    new_path = dot_if_empty && new_path.empty? ? '.' : new_path
    path[-1] == ?/ && new_path != '/' ? new_path + '/' : new_path
  end

  def self.split path, include_root_part = true
    path = simplify path, false
    if path == '/'
      include_root_part ? [ '/' ] : []
    else
      spath = path.split '/'
      spath.shift if not include_root_part and spath.first == ''
      return spath
    end
  end

  # tests if <content> (a dir or a file) is in path <path> (only checking path, not file presence)
  def self.in_path? path, content
    path_cs = split path
    subdir_cs = split content
    subdir_cs.start_with? path_cs
  end

  # return each full components of the path
  # example: components("a/b/c") = [ "a", "a/b", "a/b/c" ]
  def self.components path
    path = simplify path
    comps = []
    path.split('/').each { |comp| comps << (comps.empty? ? comp : File.join(comps.last, comp)) }
    comps.shift if comps.first == ''
    comps
  end

  # return absolute path of file <path> relative to current directory
  def self.absolute path
    absolute?(path) ? path : File.join(Dir.pwd, simplify(path))
  end

  def self.absolute? path
    path[0] == ?/
  end

  def self.relative? path
    not absolute? path
  end

  def self.relative path, base
    s_path = split path
    s_base = split base
    raise ArgumentError, "<path> is not in <base>" unless s_path.start_with? s_base
    File.join s_path[s_base.length..-1]
  end

end

# vim: foldmethod=syntax
