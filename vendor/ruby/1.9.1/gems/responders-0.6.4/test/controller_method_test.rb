require 'test_helper'

ActionController::Base.extend Responders::ControllerMethod

module FooResponder
  def to_html
    @resource << "foo"
    super
  end
end

module BarResponder
  def to_html
    @resource << "bar"
    super
  end
end

module BazResponder
  def to_html
    @resource << "baz"
    super
  end
end

class PeopleController < ApplicationController
  responders :foo, BarResponder
  
  def index
    @array = []
    respond_with(@array) do |format|
      format.html { render :text => "Success!" }
    end
  end
end

class SpecialPeopleController < PeopleController
  responders :baz
end

class ControllerMethodTest < ActionController::TestCase
  tests PeopleController

  def setup
    @controller.stubs(:polymorphic_url).returns("/")
  end

  def test_foo_responder_gets_added
    get :index
    assert assigns(:array).include? "foo"
  end
  
  def test_bar_responder_gets_added
    get :index
    assert assigns(:array).include? "bar"
  end
end

class ControllerMethodInheritanceTest < ActionController::TestCase
  tests SpecialPeopleController
  
  def setup
    @controller.stubs(:polymorphic_url).returns("/") 
  end
  
  def test_responder_is_inherited
    get :index
    assert assigns(:array).include? "foo"
    assert assigns(:array).include? "bar"
    assert assigns(:array).include? "baz"
  end
end