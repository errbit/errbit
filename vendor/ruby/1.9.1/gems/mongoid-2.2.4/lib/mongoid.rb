# encoding: utf-8

# Copyright (c) 2009 - 2011 Durran Jordan and friends.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
require "delegate"
require "time"
require "active_support/core_ext"
require 'active_support/json'
require "active_support/inflector"
require "active_support/time_with_zone"
require "active_model"
require "mongo"
require "mongoid/errors"
require "mongoid/extensions"
require "mongoid/relations"
require "mongoid/threaded"
require "mongoid/atomic"
require "mongoid/attributes"
require "mongoid/callbacks"
require "mongoid/collection"
require "mongoid/collections"
require "mongoid/config"
require "mongoid/contexts"
require "mongoid/copyable"
require "mongoid/criteria"
require "mongoid/cursor"
require "mongoid/default_scope"
require "mongoid/dirty"
require "mongoid/extras"
require "mongoid/factory"
require "mongoid/fields"
require "mongoid/finders"
require "mongoid/hierarchy"
require "mongoid/identity"
require "mongoid/identity_map"
require "mongoid/indexes"
require "mongoid/inspection"
require "mongoid/javascript"
require "mongoid/json"
require "mongoid/keys"
require "mongoid/logger"
require "mongoid/matchers"
require "mongoid/multi_parameter_attributes"
require "mongoid/multi_database"
require "mongoid/named_scope"
require "mongoid/nested_attributes"
require "mongoid/observer"
require "mongoid/persistence"
require "mongoid/safety"
require "mongoid/scope"
require "mongoid/serialization"
require "mongoid/sharding"
require "mongoid/state"
require "mongoid/timestamps"
require "mongoid/validations"
require "mongoid/versioning"
require "mongoid/components"
require "mongoid/paranoia"
require "mongoid/document"

# If we are using Rails then we will include the Mongoid railtie. This has all
# the nifty initializers that Mongoid needs.
if defined?(Rails)
  require "mongoid/railtie"
end

# If we are using any Rack based application then we need the Mongoid rack
# middleware to ensure our app is running properly.
if defined?(Rack)
  require "rack/mongoid"
end

# add english load path by default
I18n.load_path << File.join(File.dirname(__FILE__), "config", "locales", "en.yml")

module Mongoid #:nodoc
  extend self

  MONGODB_VERSION = "1.8.0"

  # Sets the Mongoid configuration options. Best used by passing a block.
  #
  # @example Set up configuration options.
  #   Mongoid.configure do |config|
  #     name = "mongoid_test"
  #     host = "localhost"
  #     config.allow_dynamic_fields = false
  #     config.master = Mongo::Connection.new.db(name)
  #   end
  #
  # @return [ Config ] The configuration obejct.
  #
  # @since 1.0.0
  def configure
    block_given? ? yield(Config) : Config
  end
  alias :config :configure

  # We can process a unit of work in Mongoid and have the identity map
  # automatically clear itself out after the work is complete.
  #
  # @example Process a unit of work.
  #   Mongoid.unit_of_work do
  #     Person.create(:title => "Sir")
  #   end
  #
  # @return [ Object ] The result of the block.
  #
  # @since 2.1.0
  def unit_of_work
    begin
      yield if block_given?
    ensure
      IdentityMap.clear
    end
  end

  # Take all the public instance methods from the Config singleton and allow
  # them to be accessed through the Mongoid module directly.
  #
  # @example Delegate the configuration methods.
  #   Mongoid.database = Mongo::Connection.new.db("test")
  #
  # @since 1.0.0
  delegate *(Config.public_instance_methods(false) +
    ActiveModel::Observing::ClassMethods.public_instance_methods(false) <<
    { :to => Config })
end
