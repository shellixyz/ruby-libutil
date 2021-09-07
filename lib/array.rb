
require_relative 'symbol'

class Array

  # apply only to a string Array
  # return min length so that all the strings beggining is uniq
  def uniq_min_length target = nil
    elts = self
    if target.nil? then
      lengths = {}
      my_elts = elts.map { |elt| elt.to_s }
      elts.each do
	elt = my_elts.pop
	lengths[elt] = my_elts.uniq_min_length my_elts
	my_elts.unshift elt
      end
      return lengths
    else
      length = 1
      elts.each do |elt|
	while length < target.length and elt[0...length] == target[0...length] do
	  length += 1
	end
      end
      return length
    end
  end

  def split(separator=nil)
    raise ArgumentError, 'a separator and a block can\'t be given at the same time' if block_given? and not separator.nil?
    elts = [ clone ]
    idx = 0
    while idx < elts.last.length
      last = elts.last
      if block_given? ? yield : last[idx] == separator then
	last.delete_at idx
	elts << last.slice!(idx .. -1)
	idx = 0
      end
      idx += 1
    end
    elts
  end

  def map_to_s
    map { |x| x.to_s }
  end

  # return true if the only element types in the array are the ones in <types>
  def only_content_types?(*types)
    all? { |x| types.include? x.class }
  end

  # return the basename of all elements using File.basename
  def basename
    map { |path| File.basename path }
  end

  # return all the elements prefixed by <dir>/
  def prefix_path dir
    map { |path| File.join(dir, path) }
  end

  # self explanatory
  # XXX: was begin_with? (sync with core, see String#start_with?)
  def start_with?(array)
    self[0...array.length] == array
  end

  def syms_suffix(*suffixes)
    map { |x| suffixes.map { |s| x + s } }.flatten
  end

  # trick for 1.8 to make concat faster
  #def concat(ary)
  #  push *ary
  #end

  def auto_convert
    map { |x| x.respond_to?(:auto_convert) ? x.auto_convert : x }
  end

  def map_with_index
    index = 0
    map { |x| yield(x, index).tap { index += 1 } }
  end

  def each_rec &block
    each { |x| x.is_a?(Array) ? x.each_rec(&block) : yield(x) }
  end

  def each_rec_with_index global_index = 0, depth = 0, &block
    each_with_index do |x, index|
      new_global_index = global_index + index
      x.is_a?(Array) ? x.map_rec(new_global_index, depth + 1, &block) : yield(new_global_index, depth, index)
    end
  end

  def map_rec &block
    map { |x| x.is_a?(Array) ? x.map_rec(&block) : yield(x) }
  end

  def map_rec_with_index global_index = 0, depth = 0, &block
    map_with_index do |x, index|
      new_global_index = global_index + index
      x.is_a?(Array) ? x.map_rec(new_global_index, depth + 1, &block) : yield(new_global_index, depth, index)
    end
  end

end

# vim: foldmethod=syntax
