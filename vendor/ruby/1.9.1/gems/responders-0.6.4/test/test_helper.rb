require 'rubygems'
require 'bundler'

Bundler.setup
require 'test/unit'
require 'mocha'

# Configure Rails
ENV["RAILS_ENV"] = "test"

require 'active_support'
require 'action_controller'
require 'active_model'
require 'rails/railtie'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'responders'

I18n.load_path << File.expand_path('../locales/en.yml', __FILE__)
I18n.reload!

Responders::Routes = ActionDispatch::Routing::RouteSet.new
Responders::Routes.draw do
  match '/admin/:action', :controller => "admin/addresses"
  match '/:controller(/:action(/:id))'
end

class ApplicationController < ActionController::Base
  include Responders::Routes.url_helpers

  self.view_paths = File.join(File.dirname(__FILE__), 'views')
  respond_to :html, :xml
end

class ActiveSupport::TestCase
  setup do
    @routes = Responders::Routes
  end
end

class Model
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :persisted, :updated_at
  alias :persisted? :persisted

  def persisted?
    @persisted
  end

  def to_xml(*args)
    "<xml />"
  end

  def initialize(updated_at=nil)
    @persisted = true
    self.updated_at = updated_at
  end
end

class Address < Model
end

class User < Model
end
