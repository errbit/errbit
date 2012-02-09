require 'test_helper'

class FlashResponder < ActionController::Responder
  include Responders::FlashResponder
end

class AddressesController < ApplicationController
  before_filter :set_resource
  self.responder = FlashResponder

  respond_to :js, :only => :create

  def action
    options = params.slice(:flash, :flash_now)
    flash[:success] = "Flash is set" if params[:set_flash]
    respond_with(@resource, options)
  end
  alias :new     :action
  alias :create  :action
  alias :update  :action
  alias :destroy :action

  def with_block
    respond_with(@resource) do |format|
      format.html { render :text => "Success!" }
    end
  end

  def another
    respond_with(@resource, :notice => "Yes, notice this!", :alert => "Warning, warning!")
  end

  protected

  def interpolation_options
    { :reference => 'Ocean Avenue' }
  end

  def set_resource
    @resource = Address.new
    @resource.errors[:fail] << "FAIL" if params[:fail]
  end
end

module Admin
  class AddressesController < ::AddressesController
  end
end

class FlashResponderTest < ActionController::TestCase
  tests AddressesController

  def setup
    Responders::FlashResponder.flash_keys = [ :success, :failure ]
    @controller.stubs(:polymorphic_url).returns("/")
  end

  def test_sets_success_flash_message_on_non_get_requests
    post :create
    assert_equal "Resource created with success", flash[:success]
  end

  def test_sets_failure_flash_message_on_not_get_requests
    post :create, :fail => true
    assert_equal "Resource could not be created", flash[:failure]
  end

  def test_does_not_set_flash_message_on_get_requests
    get :new
    assert flash.empty?
  end

  def test_sets_flash_message_for_the_current_controller
    put :update, :fail => true
    assert_equal "Oh no! We could not update your address!", flash[:failure]
  end

  def test_sets_flash_message_with_resource_name
    put :update
    assert_equal "Nice! Address was updated with success!", flash[:success]
  end

  def test_sets_flash_message_with_interpolation_options
    delete :destroy
    assert_equal "Successfully deleted the address at Ocean Avenue", flash[:success]
  end

  def test_does_not_set_flash_if_flash_false_is_given
    post :create, :flash => false
    assert flash.empty?
  end

  def test_does_not_overwrite_the_flash_if_already_set
    post :create, :set_flash => true
    assert_equal "Flash is set", flash[:success]
  end

  def test_sets_flash_message_even_if_block_is_given
    post :with_block
    assert_equal "Resource with block created with success", flash[:success]
  end

  def test_sets_now_flash_message_on_javascript_requests
    post :create, :format => :js
    assert_equal "Resource created with success", flash[:success]
    assert_flash_now :success
  end

  def test_sets_flash_message_can_be_set_to_now
    post :create, :flash_now => true
    assert_equal "Resource created with success", @controller.flash.now[:success]
    assert_flash_now :success
  end

  def test_sets_flash_message_can_be_set_to_now_only_on_success
    post :create, :flash_now => :on_success
    assert_equal "Resource created with success", @controller.flash.now[:success]
    assert_flash_now :success
  end

  def test_sets_flash_message_can_be_set_to_now_only_on_failure
    post :create, :flash_now => :on_failure
    assert_not_flash_now :success
  end

  def test_sets_message_based_on_notice_key
    Responders::FlashResponder.flash_keys = [ :notice, :alert ]
    post :another
    assert_equal "Yes, notice this!", flash[:notice]
  end

  def test_sets_message_based_on_alert_key
    Responders::FlashResponder.flash_keys = [ :notice, :alert ]
    post :another, :fail => true
    assert_equal "Warning, warning!", flash[:alert]
  end

  # If we have flash.now, it's always marked as used.
  def assert_flash_now(k)
    assert flash.instance_variable_get(:@used).include?(k.to_sym),
     "Expected #{k} to be in flash.now, but it's not."
  end

  def assert_not_flash_now(k)
    assert !flash.instance_variable_get(:@used).include?(k.to_sym),
     "Expected #{k} to not be in flash.now, but it is."
  end
end

class NamespacedFlashResponderTest < ActionController::TestCase
  tests Admin::AddressesController

  def setup
    Responders::FlashResponder.flash_keys = [ :notice, :alert ]
    @controller.stubs(:polymorphic_url).returns("/")
  end

  def test_sets_the_flash_message_based_on_the_current_controller
    put :update
    assert_equal "Admin updated address with success", flash[:notice]
  end

  def test_sets_the_flash_message_based_on_namespace_actions
    post :create
    assert_equal "Admin created address with success", flash[:notice]
  end

  def test_fallbacks_to_non_namespaced_controller_flash_message
    delete :destroy
    assert_equal "Successfully deleted the chosen address at Ocean Avenue", flash[:notice]
  end
end