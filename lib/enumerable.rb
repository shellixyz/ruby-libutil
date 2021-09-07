
module Enumerable

  # not needed with ruby 2 => [].map.with_index
  #def map_with_index
    #index = 0
    #map do |obj|
      #result = yield obj, index
      #index += 1
      #result
    #end
  #end

  def map_new_of klass
    map { |o| klass.new o }
  end

  def sum
    inject &:+
  end

end

# vim: foldmethod=syntax
