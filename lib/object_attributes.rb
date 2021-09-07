
require 'lib/meta_class'
require 'lib/callable_hash'

module Object::Attributes

  module Initializer
    def self.included dst_class
      dst_class.class_eval do

        alias_method :old_initialize, :initialize
        def initialize *args
          old_initialize *args
          attributes_init
        end
      end
    end
  end

  def alias_attributes *names
    names.each do |name|
      raise ArgumentError, "expected Symbol but got #{name.class}" unless name.is_a? Symbol
      meta_def(name) { attributes[name] }
      meta_def(name.to_s+'=') { |value| attributes[name] = value }
    end
    self
  end

  def attributes_init values = nil
    @attributes = values.nil? ? CallableHash.new : values.clone.extend(AsCallableHash)
  end

  def attributes_init_restricted *values
    @attributes = CallableHash::Restricted.new *values
  end

  attr_reader :attributes

end

# vim: foldmethod=syntax
