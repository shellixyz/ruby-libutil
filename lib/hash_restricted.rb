
class Hash

  class Restricted < Hash

    module Error

      class InvalidKey < Exception; end

    end

    def clone
      super.tap { |cl| cl.instance_variable_set :@allowed_keys, allowed_keys.clone }
    end

    def replace hash
      if hash.is_a? self.class
	allowed_keys.replace hash.allowed_keys
      else
	allowed_keys.replace hash.keys
      end
      super
    end

    def merge hash
      nhash = clone.update hash
      if hash.is_a? self.class
	nhash.allowed_keys.merge(allowed_keys + hash.keys)
      else
	nhash.allowed_keys.merge hash.keys
      end
      return nhash
    end

    def update hash
      if hash.is_a? self.class
	allowed_keys.merge hash.allowed_keys
      else
	allowed_keys.merge hash.keys
      end
      super
    end

    def replace_restricted hash
      assert_allowed_keys *hash.keys
      replace hash
    end

    def merge_restricted hash
      assert_allowed_keys *hash.keys
      update hash
    end

    def merge_restricted! hash, &block
      assert_allowed_keys *hash.keys
      merge! hash, &block
    end

    def update_restricted hash, &block
      merge_restricted! hash, &block
    end

    def lookup_restricted key
      assert_allowed_keys key
      self[key]
    end

    def store_restricted key, value
      assert_allowed_keys key
      store key, value
    end

    def values_at_restricted *keys
      assert_allowed_keys *keys
      values_at *keys
    end

    def assert_allowed_keys *keys
      forbidden_keys = forbidden_keys_in(*keys)
      raise Error::InvalidKey, "use of forbidden keys: #{forbidden_keys.to_a.join(', ')}" unless forbidden_keys.empty?
    end

    def forbidden_keys_in *keys
      keys = Set.new keys
      keys - (keys & allowed_keys)
    end

    attr_reader :allowed_keys

  end

end

# vim: foldmethod=syntax
