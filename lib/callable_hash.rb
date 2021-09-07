
require 'rubygems'
require 'set'
require_relative 'hash_restricted'

module AsCallableHash

  def method_missing method, *args
    method_s = method.to_s
    case method_s[-1]
    when ?=
      key = method_s[0..-2].to_sym
      raise ArgumentError, "expected 1 argument, got #{args.length}" unless args.length == 1
      self[key] = args.first
    when ?!
      key = method_s[0..-2].to_sym
      raise ArgumentError, "expected 0 argument, got #{args.length}" unless args.empty?
      raise ArgumentError, "uninitialized key: #{key}" unless has_key? key
      self[key]
    else
      key = method
      raise ArgumentError, "expected 0 argument, got #{args.length}" unless args.empty?
      self[key]
    end
  end

end

class CallableHash < Hash

  class Restricted < Hash::Restricted

    def initialize *values, &block
      super &block
      @allowed_keys = Set.new
      values.each do |value|
	case
	when value.is_a?(Symbol)
	  allowed_keys.add value
	when value.is_a?(Hash)
	  first_key_not_symbol = value.keys.find { |k| not k.is_a? Symbol }
	  raise ArgumentError, "Symbol expected as keys, got #{first_key_not_symbol.class}" unless first_key_not_symbol.nil?
	  allowed_keys.merge value.keys
	  update value
	end
      end
    end

    def method_missing method, *args
      method_s = method.to_s
      if method_s[-1] == ?=
	key = method_s[0..-2].to_sym
	super unless allowed_keys.include? key
	raise ArgumentError, "expected 1 argument, got #{args.length}" unless args.length == 1
	self[key] = args.first
      else
	key = method
	super unless allowed_keys.include? key
	raise ArgumentError, "expected 0 argument, got #{args.length}" unless args.empty?
	self[key]
      end
    end

    #def forbidden_keys_in *keys
    #  bad_key = keys.find { |key| not key.is_a? Symbol }
    #  raise ArgumentError, "expected Symbols, got #{bad_key.class}" if bad_key
    #  super
    #end

  end

  include AsCallableHash

end

# vim: foldmethod=syntax
