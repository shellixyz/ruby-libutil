
require 'lib/meta_class'

module X

  def self.extended dst_obj
    puts "extending #{dst_obj.inspect}"
    #meta = class << dst_obj; self; end
    #included meta
    #class << dst_obj
      #include X
    #end
    #class << dst_obj; self; end.send :include, self
    dst_obj.meta_include self
  end

  def self.included dst_class
    puts "included in #{dst_class.to_s}"
    dst_class.class_eval do

      #alias_method :old_hello, :hello

      def hello
	puts "X hello !"
	#old_hello
	super
      end

    end
  end

  def hellox
    puts "hellox"
  end

end

class Y

  def self.new_with_x
    new.extend X
  end

  def hello
    puts 'Y hello !'
  end

end

if $0 == __FILE__

  require 'pp'

  y = Y.new_with_x

  puts
  pp y
  puts

  y.hellox
  y.hello

end
