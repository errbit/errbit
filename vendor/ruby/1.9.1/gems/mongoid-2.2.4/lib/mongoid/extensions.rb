# encoding: utf-8
require "mongoid/extensions/array/deletion"
require "mongoid/extensions/false_class/equality"
require "mongoid/extensions/hash/criteria_helpers"
require "mongoid/extensions/hash/scoping"
require "mongoid/extensions/integer/checks"
require "mongoid/extensions/nil/collectionization"
require "mongoid/extensions/object/checks"
require "mongoid/extensions/object/reflections"
require "mongoid/extensions/object/substitutable"
require "mongoid/extensions/object/yoda"
require "mongoid/extensions/proc/scoping"
require "mongoid/extensions/string/checks"
require "mongoid/extensions/string/conversions"
require "mongoid/extensions/string/inflections"
require "mongoid/extensions/symbol/inflections"
require "mongoid/extensions/true_class/equality"
require "mongoid/extensions/object_id/conversions"

class Array #:nodoc
  include Mongoid::Extensions::Array::Deletion
end

class Binary; end #:nodoc:
unless defined?(Boolean)
  class Boolean; end
end

class FalseClass #:nodoc
  include Mongoid::Extensions::FalseClass::Equality
end

class Hash #:nodoc
  include Mongoid::Extensions::Hash::CriteriaHelpers
  include Mongoid::Extensions::Hash::Scoping
end

class Integer #:nodoc
  include Mongoid::Extensions::Integer::Checks
end

class NilClass #:nodoc
  include Mongoid::Extensions::Nil::Collectionization
end

class Object #:nodoc:
  include Mongoid::Extensions::Object::Checks
  include Mongoid::Extensions::Object::Reflections
  include Mongoid::Extensions::Object::Substitutable
  include Mongoid::Extensions::Object::Yoda
end

class Proc #:nodoc:
  include Mongoid::Extensions::Proc::Scoping
end

class String #:nodoc
  include Mongoid::Extensions::String::Checks
  include Mongoid::Extensions::String::Conversions
  include Mongoid::Extensions::String::Inflections
end

class Symbol #:nodoc
  remove_method :size if instance_methods.include? :size # temporal fix for ruby 1.9
  include Mongoid::Extensions::Symbol::Inflections
end

class TrueClass #:nodoc
  include Mongoid::Extensions::TrueClass::Equality
end

class BSON::ObjectId #:nodoc
  extend Mongoid::Extensions::ObjectId::Conversions
  def as_json(options = nil)
    to_s
  end
  def to_xml(options = nil)
    ActiveSupport::XmlMini.to_tag(options[:root], self.to_s, options)
  end
end
