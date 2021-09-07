
require 'test/unit'
require 'lib/term_menu'

class TestMenu < Test::Unit::TestCase

  def test_callbacks
    command_pass = false
    invalid_command_pass = false
    result = nil
    d0s = nil
    d1s = nil
    assert_nothing_raised do
      result = Term::Menu::Test.call('m 1', "menu ? ") do |menu|
	menu.on_invalid_command do |invalid_command|
	  invalid_command_pass = true
	end
	menu.on /\Am(?:\s+(\d+)(?:\s+(\d+))?)?\Z/ do |d0, d1|
	  command_pass = true
	  d0s = d0
	  d1s = d1
	end
      end
    end
    assert_equal d0s, 1
    assert_nil d1s
    assert_equal invalid_command_pass, false
    assert_equal command_pass, true
    assert_equal result, true
  end

  def test_default_command
    command_pass = false
    invalid_command_pass = false
    result = nil
    d0s = nil
    d1s = nil
    assert_nothing_raised do
      result = Term::Menu::Test.call('', "menu ? ", 'm 1 2') do |menu|
	menu.on_invalid_command do |invalid_command|
	  invalid_command_pass = true
	end
	menu.on /\Am(?:\s+(\d+)(?:\s+(\d+))?)?\Z/ do |d0, d1|
	  command_pass = true
	  d0s = d0
	  d1s = d1
	end
      end
    end
    assert_equal d0s, 1
    assert_equal d1s, 2
    assert_equal invalid_command_pass, false
    assert_equal command_pass, true
    assert_equal result, true
  end

  def test_callbacks_control_break
    command_pass = false
    invalid_command_pass = false
    result = nil
    assert_nothing_raised do
      result = Term::Menu::Test.call('', "menu ? ", 'm 1') do |menu|
	menu.on_invalid_command do |invalid_command|
	  invalid_command_pass = true
	end
	menu.on /\Am(?:\s+(\d+)(?:\s+(\d+))?)?\Z/ do |d0, d1|
	  menu.control.break
	  command_pass = true
	end
      end
    end
    assert_equal invalid_command_pass, false
    assert_equal command_pass, false
    assert_nil result
  end

  def test_callbacks_control_return
    command_pass = false
    invalid_command_pass = false
    result = nil
    sample = 'sample'
    assert_nothing_raised do
      result = Term::Menu::Test.call('', "menu ? ", 'm 1') do |menu|
	menu.on_invalid_command do |invalid_command|
	  invalid_command_pass = true
	end
	menu.on /\Am(?:\s+(\d+)(?:\s+(\d+))?)?\Z/ do |d0, d1|
	  menu.control.return sample
	  command_pass = true
	end
      end
    end
    assert_equal invalid_command_pass, false
    assert_equal command_pass, false
    assert_same result, sample
  end

  def test_outside_commands
    command_pass = false
    invalid_command_pass = false
    result = nil
    d0s = nil
    d1s = nil
    assert_nothing_raised do

      commands = Term::Menu::Commands.new do |commands|

	commands.on /\Am(?:\s+(\d+)(?:\s+(\d+))?)?\Z/ do |menu, d0, d1|
	  command_pass = true
	  d0s = d0
	  d1s = d1
	end

      end

      result = Term::Menu::Test.call('m 1', "menu ? ", nil, commands) do |menu|
	menu.on_invalid_command do |invalid_command|
	  invalid_command_pass = true
	end
      end

    end
    assert_equal d0s, 1
    assert_nil d1s
    assert_equal invalid_command_pass, false
    assert_equal command_pass, true
    assert_equal result, true
  end

  def test_without_main_block
    command_pass = false
    invalid_command_pass = false
    result = nil
    d0s = nil
    d1s = nil
    assert_nothing_raised do
      menu = Term::Menu::Test.new

      menu.on_invalid_command do |invalid_command|
	invalid_command_pass = true
      end

      menu.on /\Am(?:\s+(\d+)(?:\s+(\d+))?)?\Z/ do |d0, d1|
	command_pass = true
	d0s = d0
	d1s = d1
      end

      result = menu.call 'm 1', "menu ? "
    end
    assert_equal d0s, 1
    assert_nil d1s
    assert_equal invalid_command_pass, false
    assert_equal command_pass, true
    assert_equal result, true
  end

  def test_each
    invalid_command_pass = false
    result = nil
    collection = [ 1, 2, 3 ]
    collection_copy = collection.clone
    got_lefts = []
    got_items = []
    got_command_values = []
    assert_nothing_raised do
      result = Term::Menu::Test.each('m 1', collection, "menu ? ") do |menu|
	menu.on_invalid_command do |invalid_command|
	  invalid_command_pass = true
	end
	menu.on /\Am(?:\s+(\d+)(?:\s+(\d+))?)?\Z/ do |left, item, *values|
	  got_lefts << left
	  got_items << item
	  got_command_values << values
	end
      end
    end
    assert_equal collection_copy, collection
    assert_equal [ 2, 3 ], got_lefts[0]
    assert_equal [ 3 ], got_lefts[1]
    assert_equal [], got_lefts[2]
    assert_equal got_items, collection_copy
    got_command_values.each { |values| assert_equal values, [ 1, nil ] }
    assert_equal invalid_command_pass, false
    assert_equal result, true
  end

end

# vim: foldmethod=syntax
