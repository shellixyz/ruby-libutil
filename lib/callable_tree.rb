
require_relative 'callable_hash'

class CallableTree < CallableHash

  module Error

    class InvalidKey < Exception; end

  end

  alias :old_lookup :[]
  def [] *key
    raise ArgumentError, "missing argument" if key.empty?
    if key.length == 1 and key.first.is_a? Symbol
      super key.first
    else
      key_parts = split_key *key
      leaf = key_parts.pop
      node = search_node *key_parts
      node[leaf]
    end
  end

  alias :old_store :[]=
  def []= *args
    value, key = args.pop, args
    raise ArgumentError, "missing argument" if key.empty?
    if key.length == 1 and key.first.is_a? Symbol
      super key.first, value
    else
      key_parts = split_key *key
      leaf = key_parts.pop
      node = search_node true, *key_parts
      node[leaf] = value
    end
  end

  def search_node *key
    raise ArgumentError, "missing argument" if key.empty?
    create_node = key.shift if [ false, true ].include? key.first
    key =  split_key(*key) unless key.all? { |kp| kp.is_a? Symbol }
    search_pos = 0
    search_node = self
    while search_pos < key.length
      search_key = key[search_pos]
      search_node =
        if search_node.has_key? search_key
          search_node.old_lookup(search_key).tap do |search_node|
            raise Error::InvalidKey, "value encountered in path: #{[ key[0..search_pos].join('/'), key[search_pos+1..-1].join('/') ].join('|')}" \
              unless search_node.is_a? CallableTree
          end
        else
          raise Error::InvalidKey, "inexistant node: #{[ key[0..search_pos].join('/'), key[search_pos+1..-1].join('/') ].join('|')}" \
            unless create_node
          search_node.old_store(search_key, self.class.new)
        end
      search_pos += 1
    end
    return search_node

  end

  protected

  def split_key *key
    key.map { |ikey| ikey.is_a?(Symbol) ? ikey : ikey.split('/').map(&:to_sym) }.flatten
  end

end

class CallableTree::Restricted < CallableTree

  module Error

    class Uninitialized < Exception; end

  end

  def [] *key
    raise ArgumentError, "missing argument" if key.empty?
    if key.length == 1 and key.first.is_a? Symbol
      key = key.first
      raise Error::Uninitialized, "uninitialized value: #{key}" unless has_key? key
      super key
    else
      key_parts = split_key *key
      leaf = key_parts.pop
      node = search_node *key_parts
      raise Error::InvalidKey, "value encountered in path: #{[ key_parts.join('/'), leaf ].join('|')}" unless node.is_a? self.class
      raise Error::Uninitialized, "uninitialized value: #{[ key_parts.join('/'), leaf ].join('|')}" unless node.has_key? leaf
      node[leaf]
    end
  end

end
