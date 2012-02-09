require 'test_helper'

class CollectionResponder < ActionController::Responder
  include Responders::CollectionResponder
end

class CollectionController < ApplicationController
  self.responder = CollectionResponder

  def single
    respond_with Address.new
  end

  def namespaced
    respond_with :admin, Address.new
  end

  def nested
    respond_with User.new, Address.new
  end

  def only_symbols
    respond_with :admin, :addresses
  end

  def with_location
    respond_with Address.new, :location => "given_location"
  end
end

class CollectionResponderTest < ActionController::TestCase
  tests CollectionController

  def test_collection_with_single_resource
    @controller.expects(:addresses_url).returns("addresses_url")
    post :single
    assert_redirected_to "addresses_url"
  end

  def test_collection_with_namespaced_resource
    @controller.expects(:admin_addresses_url).returns("admin_addresses_url")
    put :namespaced
    assert_redirected_to "admin_addresses_url"
  end

  def test_collection_with_nested_resource
    @controller.expects(:user_addresses_url).returns("user_addresses_url")
    delete :nested
    assert_redirected_to "user_addresses_url"
  end

  def test_collection_respects_location_option
    delete :with_location
    assert_redirected_to "given_location"
  end

  def test_collection_respects_only_symbols
    @controller.expects(:admin_addresses_url).returns("admin_addresses_url")
    post :only_symbols
    assert_redirected_to "admin_addresses_url"
  end
end