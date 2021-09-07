
require 'lib/term'
require 'lib/array'
require 'lib/callbacks'

module Term

  class Menu

    CALLBACKS = :before_menu, :after_menu, :on_command, :on_invalid_command, :on_collection_end

    class InvalidCommand < Exception; end

    class Test < Menu

      def call input, text, default = nil, *commands
	@input = input
	super text, default, *commands
      end

      def each input, collection, text, default = nil, *commands
	@input = input
	super collection, text, default, *commands
      end

      private

      def ask(text)
	@input
      end

    end

    class Commands < Callbacks

      def initialize
	super
	yield self if block_given?
      end

      def check_arg_type(arg, arg_name, *valid_types)
	raise ArgumentError, "argument #{arg} must be of one of these classes: #{valid_types.map(&:to_s).join(', ')}" unless valid_types.any? { |klass| arg.is_a? klass }
      end

      def on(match, &block)
	check_arg_type match, 'match', Symbol, String, Regexp
	super
      end

      def dispatch(command, *args)
	raise ArgumentError unless command.is_a? String
	each do |match, block|
	  case
	  when match.is_a?(Symbol) || match.is_a?(String)
	    if command == match.to_s
	      block.call *args
	      return true
	    end
	  when match.is_a?(Regexp)
	    mdata = command.match match
	    unless mdata.nil?
	      block.call *(args + mdata.captures.auto_convert)
	      return true
	    end
	  end
	end
	return false
      end

    end

    module FlowControlExceptions

      class Break < Exception; end

      class Return < Exception

	def initialize(value)
	  super()
	  @value = value
	end

	attr_reader :value

      end

    end

    class FlowControl

      include FlowControlExceptions

      def self.break
	raise Break
      end

      def self.return(value)
	raise Return, value
      end

    end

    class FlowControlEach

      include FlowControlExceptions
      class Retry < Exception; end
      class Redo < Exception; end
      class RedoLater < Exception; end
      class Next < Exception; end

      def self.next
	raise Next
      end

      def self.redo
	raise Redo
      end

      def self.redo_later
	raise Later
      end

      def self.retry
	raise Retry
      end

      def self.return(value)
	raise Return, value
      end

      def self.break
	raise Break
      end

    end

    def self.call(text, default = nil, *commands, &block)
      new.call text, default, *commands, &block
    end

    def self.each(collection, text, default = nil, *commands, &block)
      new.each collection, text, default, *commands, &block
    end

    def call(text = nil, default = nil, *commands, &block)
      text ||= @default_text || ''
      default ||= @default_command
      with_control(FlowControl) do
	menu_with_args text, [], default, *commands, &block
      end
    end

    def each(collection, text = nil, default = nil, *commands, &block)
      text ||= @default_text || ''
      default ||= @default_command
      raise ArgumentError, "collection must respond to shift, unshift and push methods: got #{collection.class}" unless [ :shift, :unshift, :push ].all? { |method| collection.respond_to? method }
      check_arg_array 'commands', commands, Commands
      collection = collection.clone
      with_control FlowControlEach do
	begin
	  while not collection.empty?
	    item = collection.shift
	    begin
	      @callbacks.call_if_defined :before_menu, collection, item
	      menu_with_args text, [ collection.clone, item ], default, *commands, &block
	    rescue FlowControlEach::Redo
	      collection.unshift item
	    rescue FlowControlEach::RedoLater
	      collection.push item
	    rescue FlowControlEach::Break
	      return nil
	    rescue FlowControlEach::Return => error
	      return error.value
	    rescue FlowControlEach::Next
	    end
	    @callbacks.call_if_defined :after_menu, collection, item
	  end
	  @callbacks.call_if_defined :on_collection_end
	rescue FlowControlEach::Retry
	  collection = collection.clone
	  retry
	end
      end
      return true
    end

    def control
      raise 'not in menu' unless in_menu?
      @control
    end

    def initialize(default_text = nil, default_command = nil)
      @default_text = default_text
      @default_command = default_command
      @commands = Commands.new
      @callbacks = RestrictedCallbacks.new *CALLBACKS
      yield self if block_given?
    end

    def on(match, &block)
      @commands.on(match, &block)
    end

    def method_missing(method, *args, &block)
      @callbacks.on method, &block if CALLBACKS.include? method
    end

    private

    def command_dispatch(command, args, mcommands)
      mcommands.each do |mcommand|
	case
	when mcommand.is_a?(Regexp)
	  mdata = command.match mcommand
	  return OpenStruct.new :name => mdata[1].to_s, :args => (args + mdata[2..-1].auto_convert) if mdata
	when mcommand.is_a?(Symbol) || mcommand.is_a?(String)
	  return(args.empty? ? mcommand.to_s : OpenStruct.new(:name => mcommand.to_s, :args => args)) if command == mcommand.to_s
	when mcommand.is_a?(Hash)
	  mcommand.each do |match, action|
	    case
	    when match.is_a?(Regexp)
	      mdata = command.match match
	      if mdata
		case
		when action.is_a?(String) || match.is_a?(Symbol)
		  return OpenStruct.new :name => action.to_s, :args => (args + mdata.captures.auto_convert)
		when action.is_a?(Proc)
		  action.call *(args + mdata.captures.auto_convert)
		  return true
		else
		  raise ArgumentError, "action: type non pris en charge: #{action.class}"
		end
	      end
	    when match.is_a?(String) || match.is_a?(Symbol)
	      if command == match.to_s
		case
		when action.is_a?(String) || value.is_a?(Symbol)
		  return action.to_s
		when action.is_a?(Proc)
		  action.call *args
		  return true
		else
		  raise ArgumentError, "action: type non pris en charge: #{action.class}"
		end
	      end
	    else
	      raise ArgumentError, "match: type non pris en charge: #{match.class}"
	    end
	  end
	when mcommand.is_a?(Commands)
	  return mcommand.dispatch(command, *args)
	else
	  raise ArgumentError, "mcommand: type non pris en charge: #{mcommand.class}"
	end
      end
      false
    end

    def check_arg_array_command_hashes(array)
      array.each do |command|
	if command.is_a? Hash
	  command.each do |match, action|
	    case
	    when match.is_a?(Regexp)
	      raise ArgumentError, "#{match.class} match found with action of unexpected type: #{action.class}" unless [ Symbol, String, Proc ].any? { |klass| action.is_a? klass }
	    when match.is_a?(String) || match.is_a?(Symbol)
	      raise ArgumentError, "#{match.class} match found with action of unexpected type: #{action.class}" unless [ Symbol, String, Proc ].any? { |klass| action.is_a? klass }
	    else
	      raise ArgumentError, "found match with unexpected type: #{match.class}"
	    end
	  end
	end
      end
      nil
    end

    def check_arg_array(arg_name, array_arg, *classes)
      array_arg.each { |arg| raise ArgumentError, "<#{arg_name}> only accept #{classes.map(&:to_s).join(', ')} elements: got #{arg.class}" unless classes.any? { |klass| arg.is_a? klass } }
      check_arg_array_command_hashes array_arg
    end

    def in_menu?
      @in_menu == true
    end

    def in_menu
      @in_menu = true
      result = yield
      @in_menu = false
      return result
    end

    def with_control(control)
      old_control = @control
      @control = control
      result = in_menu { yield }
      @control = old_control
      return result
    end

    def ask(text)
      Term.ask text
    end

    def menu_with_args(text, args, default, *mcommands)
      check_arg_array 'mcommands', mcommands, String, Regexp, Symbol, Hash, Commands
      yield self if block_given?
      raise 'calling menu without commands' if mcommands.empty? and @commands.empty?
      loop do
	begin
	  command = ask text
	  return nil if command.nil?
	  command = default if command == ''
	  raise Menu::InvalidCommand if command.nil?
	  dispatch_result = command_dispatch command, [ self, *args ], mcommands
	  return dispatch_result if dispatch_result
	  break if @commands.dispatch command, *args # return true if command match
	  if @on_command
	    @on_command.call self, command, *args
	  else
	    raise Menu::InvalidCommand
	  end
	rescue Menu::InvalidCommand
	  puts 'Invalid command' unless call_invalid_command_block command
	rescue FlowControl::Break
	  return nil
	rescue FlowControl::Return => error
	  return error.value
	end
      end
      true
    end

    def call_invalid_command_block(command)
      if @callbacks.defined? :on_invalid_command
	@callbacks.call :on_invalid_command, command
	true
      else
	false
      end
    end

  end

  def self.menu *args, &block
    Menu.call *args, &block
  end

  def self.menu_each *args, &block
    Menu.each *args, &block
  end

end

# vim: foldmethod=syntax
