
require 'lib/meta_class'

module Class::Features

  class Definitions < Hash

    def update *features
      features.each do |ifeatures|
	ifeatures.each do |feature, modules|
	  if modules.nil?
	    delete feature
	  else
	    old_modules = self[feature] || []
	    old_modules = [ old_modules ] unless old_modules.is_a? Array
	    modules = [ modules ] unless modules.is_a? Array
	    self[feature] = old_modules + modules
	  end
	end
      end
      return self
    end

    # TODO: #new(*features) qui est similaire à update mais lance une exception si une feature du même nom a deja ete enregistrée

    alias_method :names, :keys

  end

  class Interface

    def initialize target
      @definitions = Definitions.new
      @target = target
    end

    def add *features
      unless features.empty?
	features.each do |feature|
	  feature_modules = definitions[feature]
	  raise ArgumentError, "invalid feature: #{feature}" if feature_modules.nil?
	  feature_modules = [ feature_modules ] unless feature_modules.is_a? Array
	  feature_modules.each { |m| target.extend_unless_include m }
	end
      end
      target
    end

    def current
      available.find_all do |name|
	modules = definitions[name]
	modules.all? { |m| target.obj_include? m }
      end
    end

    def available
      definitions.names
    end

    attr_reader :definitions, :target

  end

  module ClassMethods

    def new_with features, *args, &block
      features = [ features ] unless features.is_a? Array
      new(*args, &block).features.add *features
    end

  end

  def features
    @features ||= Interface.new self
  end

  def self.included dst_class
    dst_class.extend ClassMethods
  end

#  def add_features *features
#    unless features.empty?
#      available_features = self.available_features
#      features.each do |feature|
#	feature_modules = available_features[feature]
#	raise ArgumentError, "invalid feature: #{feature}" if feature_modules.nil?
#	feature_modules = [ feature_modules ] unless feature_modules.is_a? Array
#	feature_modules.each { |m| extend_unless_include m }
#      end
#    end
#    self
#  end
#
#  protected
#
#  def merge_features *features
#    features_updated = {}
#    features.each do |ifeatures|
#      ifeatures.each do |feature, modules|
#	old_modules = features_updated[feature] || []
#	old_modules = [ old_modules ] unless old_modules.is_a? Array
#	modules = [ modules ] unless modules.is_a? Array
#	features_updated[feature] = old_modules + modules
#      end
#    end
#    return features_updated
#  end

end
