require 'rubygems'
require 'bundler'

Bundler.setup

require 'test/unit'
require 'mocha'

ENV["RAILS_ENV"] = "test"
RAILS_ROOT = "anywhere"

require "active_support"
require "active_model"
require "action_controller"

I18n.load_path << File.join(File.dirname(__FILE__), 'locales', 'en.yml')
I18n.reload!

class ApplicationController < ActionController::Base; end

# Add IR to load path and load the main file
$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'inherited_resources'

ActionController::Base.view_paths = File.join(File.dirname(__FILE__), 'views')

InheritedResources::Routes = ActionDispatch::Routing::RouteSet.new
InheritedResources::Routes.draw do
  match ':controller(/:action(/:id))'
  match ':controller(/:action)'
  resources 'posts'
  root :to => 'posts#index'
end

ActionController::Base.send :include, InheritedResources::Routes.url_helpers

# Add app base to load path
$:.unshift File.expand_path(File.dirname(__FILE__) + '/../app/controllers')
require 'inherited_resources/base'

class ActiveSupport::TestCase
  setup do
    @routes = InheritedResources::Routes
  end
end
