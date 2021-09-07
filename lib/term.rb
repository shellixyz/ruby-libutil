
require 'rubygems'
require 'ostruct'
require 'readline'

module Term

  def self.ask(text)
    Readline.readline text
  end

  def self.ask_for_float text
      Float Readline.readline(text)
  rescue ArgumentError
      STDERR.puts "Error: invalid decimal number, try again"
      retry
  end

  def self.ask_for_integer text
      Integer Readline.readline(text)
  rescue ArgumentError
      STDERR.puts "Error: invalid integer number, try again"
      retry
  end

  def self.ask_yes_no text, default = false
      loop do
          result = ask text
          case
          when result.empty? then return default
          when %w{ yes y }.include?(result) then return true
          when %w{ no n }.include?(result) then return false
          else STDERR.puts "Invalid answer, waiting for y, n, yes, no"
          end
      end
  end

  # enable/diable echoing password on current terminal
  def self.echo=(status)
    system("stty #{'-' if not status}echo > /dev/null 2>&1")
    raise 'stty failed' if $? != 0
  end

  def self.echo!
    self.tap { |x| x.echo = true }
  end

  def self.noecho!
    self.tap { |x| x.echo = false }
  end

  # read password from STDIN hidding chars
  def self.readpassword(prompt)
    STDERR.print prompt
    STDERR.flush
    noecho!
    STDIN.readline.tap { echo!; STDERR.puts }
  end

  # return terminal size as OpenStruct with methods height and width
  def self.size(reload = false)
    if reload or not defined? @@term_size then
      size_data = `stty size`.match /\A(\d+)\s+(\d+)\Z/
	@@term_size = OpenStruct.new :height => size_data[1].to_i, :width => size_data[2].to_i
    end
    @@term_size
  end

  def self.width(reload = false)
    size(reload).width
  end

  def self.height(reload = false)
    size(reload).height
  end

  def self.keep_settings
    old_settings = `stty -g`
    yield
    system "stty #{old_settings}"
    nil
  end

  def self.message_pause str
      STDOUT.message_pause str
  end

  def self.hide_cursor
      STDOUT.hide_cursor!
      yield
  ensure
      STDOUT.show_cursor!
  end

end

class IO

  def cursor_visibility= value
    print value ? "\e[?25h" : "\e[?25l"
  end

  def show_cursor!
    self.tap { |x| x.cursor_visibility = true }
  end

  def hide_cursor!
    self.tap { |x| x.cursor_visibility = false }
  end

  def wrap= value
    print value ? "\e[?7h" : "\e[?7l"
  end

  def wrap!
    self.tap { |x| x.wrap = true }
  end

  def nowrap!
    self.tap { |x| x.wrap = false }
  end

  def clear_line_from_cursor direction
    case direction
    when :right
      print "\e[0K"
    when :left
      print "\e[1K"
    else
      raise "invalid direction: #{direction.inspect}"
    end
    self
  end

  def clear_line
    print "\e[2K"
    self
  end

  def clear_screen
    print "\e[2J"
    self
  end

  def clear_screen_from_cursor direction
    case direction
    when :down
      print "\e[0J"
    when :up
      print "\e[1J"
    else
      raise "invalid direction: #{direction.inspect}"
    end
    self
  end

  def move_cursor_on_first_column
    print "\r"
    self
  end

  def update_line str
    print "\r\e[2K" + str
    flush
  end

  def one_line_progress_start! title: nil
    puts title if title
    nowrap!.hide_cursor!
    self
  end

  def one_line_progress_stop! keep_line: true, post_line: nil
    puts if keep_line
    if post_line == true
      puts
    else
      puts post_line unless post_line.nil?
    end
    wrap!.show_cursor!
    self
  end

  def one_line_progress title: nil, post_line: nil, keep_line: true
    one_line_progress_start! title: title
    yield
  ensure
    one_line_progress_stop! post_line: post_line, keep_line: keep_line
  end

  def message_pause str
    print str
    flush
    STDIN.readline
  end

  def move_cursor_home
    write "\e[H"
  end

  def move_cursor_to line, column
    write "\e[#{line};#{column}H"
  end

  def move_cursor_up count = 1
    write "\e[#{count}A"
  end

  def move_cursor_down count = 1
    write "\e[#{count}B"
  end

  def move_cursor_right count = 1
    write "\e[#{count}C"
  end

  def move_cursor_left count = 1
    write "\e[#{count}D"
  end

  def move_cursor args
    move_cursor_up args[:up] if args.has_key? :up
    move_cursor_down args[:down] if args.has_key? :down
    move_cursor_right args[:right] if args.has_key? :right
    move_cursor_left args[:left] if args.has_key? :left
    nil
  end

  def save_cursor_position
    write "\e[s"
  end

  def restore_cursor_position
    write "\e[u"
  end

  def keep_cursor_position
    save_cursor_position
    yield
  ensure
    restore_cursor_position
  end

end

# vim: foldmethod=syntax
