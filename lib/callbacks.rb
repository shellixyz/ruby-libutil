
module Callbacks

  class Callback

    def initialize block, options = nil
      @keep_result = options && options.has_key?(:keep_result) ? options[:keep_result] : true
      @proc = block
    end

    def keep_result?
      @keep_result
    end

    def call *args
      result = @proc.call *args
      if keep_result?
	return result
      else
	args.length == 1 ? args.first : args
      end
    end

    def vcall args = nil, *values
      values.concat args
      call *values
    end

    attr_writer :keep_result
    attr_accessor :proc

  end

  class SmartCallback < Callback

    def self.new iterator, options = nil, &block
      iterator ? super : block
    end

    def initialize iterator, options = nil, &block
      raise ArgumentError, "iterator must be a Symbol, got #{iterator.class}" unless iterator.is_a? Symbol
      @iterator = iterator
      super options, &block
    end

    def call object, *args
      if args.empty?
	object.send iterator, *args, &self
      else
	object.send(iterator) { |*iargs| super *(iargs + args) }
      end
    end

    def vcall args = nil, *values
      object = values.shift
      values.concat args
      call object, *values
    end

    attr_reader :iterator, :options

  end

  class Sequence < Array

    # with 1.9 arg spec could be *values, args
    def vcall args = nil, *values
      values_length_was = values.length
      args = args.nil? ? [] : (args.is_a?(Array) ? args : [ args ])
      if values.empty?
	call *args
      else
	values.concat args			# prepare values for first call
	each_with_index do |callback, index|
	  values = callback.call *values
	  unless index == length - 1		# if last callback dont touch values, else build next call args
	    if values_length_was == 1		# if values is in reality a "value"
	      values = [ values, *args ]	#   then build a new array with value and args
	    else				# else
	      values.concat args		#   append args to values
	    end
	  end
	end
      end
      return values
    end

    def call *args
      each_with_index do |callback, index|
	args = callback.call *args
	args = [ args ] if callback.is_a?(SmartCallback) and not index == length - 1
      end
      return args
    end

  end

  class Hash < Hash

    module Error
      class UndefinedName < StandardError; end
    end

    alias :defined? :has_key?

    def initialize options = nil
      self.force_proc_convertion = options[:force_proc_convertion] if options
      @call_stats = ::Hash.new 0
    end

    def define! name, options = nil, &block
      raise ArgumentError, 'expecting a block' unless block_given?
      if options and iterator = options.delete(:iterator)
	define_smart! name, iterator, options, &block
      else
	define_callback name, prepare_callback(name, block, options), options
      end
    end

    def define name, options = nil, &block
      raise ArgumentError, "already defined: #{name.inspect}: use define! to redefine" if has_key? name
      define! name, options, &block
    end

    def define_smart! name, iterator, options = nil, &block
      raise ArgumentError, 'expecting a block' unless block_given?
      if iterator
	define_callback name, SmartCallback.new(iterator, options, &block), options
      else
	define! name, options, &block
      end
    end

    def define_smart name, iterator, options = nil, &block
      raise ArgumentError, "already defined: #{name.inspect}: use define! to redefine" if has_key? name
      define_smart! name, iterator, options, &block
    end

    def undef! name
      delete name
      self
    end

    def undef name
      raise ArgumentError, "no defined callback with name: #{name.inspect}" unless has_key? name
      undef! name
    end

    def add name, options = nil, &block
      raise ArgumentError, 'add is expecting a block' unless block_given?
      if options and iterator = options.delete(:iterator)
	add_smart name, iterator, options, &block
      else
	add_callback name, prepare_callback(name, block, options), options
      end
    end

    def add_smart name, iterator, options = nil, &block
      raise ArgumentError, 'expecting a block' unless block_given?
      if iterator
	add_callback name, SmartCallback.new(iterator, options, &block), options
      else
	add name, options, &block
      end
    end

    def call name, *args
      callback = self[name]
      raise Error::UndefinedName, "undefined name: #{name}" unless callback
      called_callback name
      callback.call *args
    end

    def call_if_defined name, *args
      callback = self[name]
      called_callback name
      callback.call *args if callback
    end

    def call_chain name, *args
      callback = self[name]
      called_callback name
      if callback
	callback.call *args if callback
      else
	args.length == 1 ? args.first : args
      end
    end

    def vcall name, args = nil, *values
      callback = self[name]
      raise Error::UndefinedName, "undefined name: #{name}" unless callback
      called_callback name
      callback.vcall args, *values
    end

    def vcall_if_defined name, args = nil, *values
      callback = self[name]
      called_callback name
      callback.vcall args, *values if callback
    end

    def vcall_chain name, args = nil, *values
      callback = self[name]
      called_callback name
      if callback
	callback.vcall args, *values
      else
	values.length == 1 ? values.first : values
      end
    end

    def force_proc_convertion?
      @force_proc_convertion
    end

    def called? name
      call_stats.has_key? name
    end

    attr_writer :force_proc_convertion
    attr_reader :call_stats

    private

    def called_callback name
      call_stats[name] += 1
    end

    def prepare_callback name, callback, options = nil
      if force_proc_convertion? or options == false or not (options.nil? or options.empty?)
        Callback.new callback, options
      else
	callback
      end
    end

    def define_callback name, callback, options = nil
      self[name] = callback
    end

    def add_callback name, callback, options = nil
      current = self[name]
      if current
	self[name] = current = Sequence.new(1, current) unless current.is_a? Array
	current << callback
      else
	define_callback name, callback, options
      end
    end

  end

end
