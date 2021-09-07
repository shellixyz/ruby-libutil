
require_relative 'callbacks'
require_relative 'callable_tree'
require_relative 'term_color'

module Anchor

  module Catcher

    module Methods

      def capture names, call_type = nil, options = nil, &block
	[*names].each do |name|
	  anchor_catchers.add_smart name, call_type, :keep_result => false, &block
	end
      end

      def transform names, call_type = nil, options = nil, &block
	[*names].each do |name|
	  anchor_catchers.add_smart name, call_type, &block
	end
      end

      def replace *args
	if args.first.is_a? Hash
	  values, call_type, options = args
	  options ||= {}
	  values.each { |name, value| replace name, value, call_type, options }
	else
	  name, value, call_type, options = args
	  options ||= {}
	  transform(name, call_type, options) { value }
	end
      end

      def colorize names, call_type = nil, options = {}, &block
	case
	when names.is_a?(Array)
	  names.each { |name| colorize name, call_type, options, &block }
	when names.is_a?(Hash)
	  names.each do |name, color|
	    case
	    when color.is_a?(Symbol)
	      colorize(name, call_type, options) { color }
	    when color.is_a?(Hash)
	      colorize(name, call_type, options) { |value| color[value] }
	    else
	      raise ArgumentError, "invalid type, expected Symbol or Hash: #{color.inspect}"
	    end
	  end
	else
	  anchor_catchers.add_smart names, call_type do |*args|
	    color = yield *args
	    string = args.first.to_s
	    color.nil? ? string : TermColor.send(color, string)
	  end
	end
      end

    end

    module Interface

      class With

	def initialize *anchors
	  @anchors = anchors
	end

	def method_missing method, *args, &block
	  if Methods.method_defined? method
	    anchors.each { |anchor| Catcher::Interface.send method, anchor, *args, &block }
	  else
	    super
	  end
	end

	attr_reader :anchors

      end

      # effectue toutes les transformations du block avec les ancres <anchors>
      def self.with *anchors, &block
	Interface::With.new(*anchors).instance_eval &block
      end

      def self.with! *anchors, &block
	Anchor.add_call_check *anchors
	Interface::With.new(*anchors).instance_eval &block
      end

      def self.method_missing method, *args, &block
	mmatch = method.to_s.match /\A(\w+)!\Z/
	if mmatch and Methods.method_defined? mmatch[1]
	  real_method = mmatch[1]
	  send real_method, *args, &block
	  name = args.first
	  case
	  when name.is_a?(Hash) || name.is_a?(Array)
	    names = names.keys if names.is_a? Hash
	    Anchor.add_call_check *names
	  else
	    Anchor.add_call_check name
	  end
	else
	  super
	end
      end

      extend Methods

    end

  end

  module ObjectExtension

    def anchor_values *args
      raise ArgumentError, "too few arguments: minimum 1 expected, got #{args.length}"
      if args.length == 1 and args.first.is_a? Hash
	args.first.each { |name, value| anchor_catchers.smart_call_sequence_if_defined name, value }
      else
	names = args
	values = yield if anchor_catched? *names
	if args.length == 1
	  values = [ values ]
	else
	  raise ArgumentError, "expected Array from block return value but got: #{values.class}" unless values.is_a? Array
	end
	unless values.nil?
	  raise ArgumentError, "names and values length didn't match: names(#{names.length}) values(#{values.length})" if values.length != names.length
	  SyncEnumerator.new(names, values).each do |name, value|
	    anchor_catchers.smart_call_sequence_if_defined name, value
	  end
	end
      end
    end

    # anchor_values name, value, *args
    # anchor_values name, *args { called if anchor catched }
    def anchor_values name, *args
      if anchor_current_catchers
	if block_given?
	  anchor_catchers.vcall_chain name, args, yield if anchor_catched? name
	else
	  value = args.shift
	  anchor_current_catchers.vcall_chain name, args, value
	end
      else
	return args.first
      end
    end

    def anchor name, *args
      anchor_values name, self, *args
    end

    def anchor_start namespace, *args
      anchor_values namespace + '/start', self, *args
    end

    def anchor_end namespace, *args
      anchor_values namespace + '/end', self, *args
    end

    def anchor_values_start namespace, *args
      anchor_values namespace + '/start', *args
    end

    def anchor_values_end namespace, *args
      anchor_values namespace + '/end', *args
    end

    def anchor_start_end namespace, end_args = nil, start_args = nil
      anchor_values namespace + '/start', *start_args
      #if start_args.nil?
	#anchor_values(namespace + '/start')
      #else
	#start_args.is_a?(Array) ? anchor_values(namespace + '/start', *start_args) : anchor_values(namespace + '/start', start_args)
      #end
      yield.tap { anchor_values namespace + '/end', *end_args }
      #yield.tap do
	#if end_args.nil?
	  #anchor_values(namespace + '/end')
	#else
	  #end_args.is_a?(Array) ? anchor_values(namespace + '/end', *end_args) : anchor_values(namespace + '/end', end_args)
	#end
      #end
    end

    def anchor_catcher to_run_catch = nil, *args, &block
      Anchor.nested_catcher_block do
	if to_run_catch
	  Catcher::Interface.module_eval &block
	  to_run_catch.call *args
	else
	  yield Catcher::Interface
	end
      end
    end

    def anchor_catch *names, &block
      anchor_catcher { |catcher| catcher.with *names, &block }
    end

    def anchor_capture *names
      interface = CallableTree::Restricted.new
      names.each do |name|
	Catcher::Interface.capture(name) { |value| interface[name] = value }
      end
      yield interface
    end

    def anchor_catched? *anchors
      anchor_catchers and anchors.all? { |anchor| anchor_catchers.defined? anchor }
    end

    def anchor_current_catchers
      Anchor.current_catchers
    end

    def anchor_catchers
      Anchor.catchers
    end

  end

  module ClassMethods

    def nested_catcher_block
      unless current_catchers.nil?
	catchers_stack << current_catchers
	call_check_names_stack << call_check_names
	self.current_catchers = current_catchers.clone
      end
      yield(catchers).tap do
	check_called_names
	self.current_catchers = catchers_stack.pop
	self.call_check_names = call_check_names_stack.pop
      end
    end

    def call_check_names_stack
      @call_check_names_stack ||= Array.new
    end

    def catchers_stack
      @catchers_stack ||= Array.new
    end

    def catchers
      @current_catchers ||= Callbacks::Hash.new :force_proc_convertion => true
    end

    def check_called_names
      if call_check_names
	not_called = call_check_names.find_all { |name| not current_catchers.called? name }
	raise "call check: not called: #{not_called.join(', ')}" unless not_called.empty?
	self.call_check_names = nil
      end
    end

    def add_call_check *names
      self.call_check_names ||= []
      call_check_names.concat names
    end

    attr_accessor :current_catchers, :call_check_names

  end

  extend ClassMethods

end

class Object

  include Anchor::ObjectExtension

end

##########################################


# TODO: utiliser binding pour recuperer les variables locales: ex: binding.anchor(:singles)


# TEST
if $0 == __FILE__
  require 'pp'

  def factor_string
    singles = 4
    factors = [ 1, 2, 3 ]
    factors = factors.anchor(:factors0)
    separator = ' + '.anchor :separator
    singles.anchor(:singles).to_s + separator + factors.anchor(:factors).join(separator).anchor(:factor_sum)
  end

  TermColor.enable

  text = anchor_catcher method(:factor_string) do
    capture!(:factors0) { |factors| puts factors.join(', ') }
    colorize(:singles) { :green }
    transform(:singles) { |singles| '(' + singles.to_s + ')' }
    transform(:factors) { |factors| [ 0, *factors ] }
    capture(:factors) { |factors| puts factors.join(', ') }
    colorize(:factors, :map) { :yellow }
    colorize(:separator) { :bold }
    transform(:separator) { '+' }
    replace :separator, ' * '
    transform(:factor_sum) { |factor_sum| '[' + factor_sum + ']' }
  end

  pp text
  puts text

end


# vim: foldmethod=syntax
