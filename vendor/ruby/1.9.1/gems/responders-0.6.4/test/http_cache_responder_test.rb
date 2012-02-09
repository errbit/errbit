require 'test_helper'

class HttpCacheResponder < ActionController::Responder
  include Responders::HttpCacheResponder
end

class HttpCacheController < ApplicationController
  self.responder = HttpCacheResponder

  def single
    options = params.slice(:http_cache)
    response.last_modified = Time.utc(2008) if params[:last_modified]
    respond_with(Address.new(Time.utc(2009)), options)
  end

  def nested
    respond_with Address.new(Time.utc(2009)), Address.new(Time.utc(2008))
  end

  def collection
    respond_with [Address.new(Time.utc(2009)), Address.new(Time.utc(2008))]
  end

  def not_persisted
    model = Address.new(Time.utc(2009))
    model.persisted = false
    respond_with(model)
  end

  def empty
    respond_with []
  end
end

class HttpCacheResponderTest < ActionController::TestCase
  tests HttpCacheController

  def setup
    @request.accept = "application/xml"
    @controller.stubs(:polymorphic_url).returns("/")
  end

  def test_last_modified_at_is_set_with_single_resource_on_get
    get :single
    assert_equal Time.utc(2009).httpdate, @response.headers["Last-Modified"]
    assert_equal "<xml />", @response.body
    assert_equal 200, @response.status
  end

  def test_returns_not_modified_if_return_is_cache_is_still_valid
    @request.env["HTTP_IF_MODIFIED_SINCE"] = Time.utc(2009, 6).httpdate
    get :single
    assert_equal 304, @response.status
    assert_equal " ", @response.body
  end

  def test_refreshes_last_modified_if_cache_is_expired
    @request.env["HTTP_IF_MODIFIED_SINCE"] = Time.utc(2008, 6).httpdate
    get :single
    assert_equal Time.utc(2009).httpdate, @response.headers["Last-Modified"]
    assert_equal "<xml />", @response.body
    assert_equal 200, @response.status
  end

  def test_does_not_set_cache_unless_get_requests
    put :single
    assert_nil @response.headers["Last-Modified"]
    assert_equal 200, @response.status
  end

  def test_does_not_use_cache_unless_get_requests
    @request.env["HTTP_IF_MODIFIED_SINCE"] = Time.utc(2009, 6).httpdate
    put :single
    assert_equal 200, @response.status
  end

  def test_does_not_set_cache_if_http_cache_is_false
    get :single, :http_cache => false
    assert_nil @response.headers["Last-Modified"]
    assert_equal 200, @response.status
  end

  def test_does_not_use_cache_if_http_cache_is_false
    @request.env["HTTP_IF_MODIFIED_SINCE"] = Time.utc(2009, 6).httpdate
    get :single, :http_cache => false
    assert_equal 200, @response.status
  end

  def test_does_not_set_cache_for_collection
    get :collection
    assert_nil @response.headers["Last-Modified"]
    assert_not_nil @response.headers["ETag"]
    assert_equal 200, @response.status
  end

  def test_works_for_nested_resources
    get :nested
    assert_equal Time.utc(2009).httpdate, @response.headers["Last-Modified"]
    assert_match /xml/, @response.body
    assert_equal 200, @response.status
  end

  def test_work_with_an_empty_array
    get :empty
    assert_nil @response.headers["Last-Modified"]
    assert_match /xml/, @response.body
    assert_equal 200, @response.status
  end

  def test_it_does_not_set_body_etag_for_single_resource
    get :single
    assert_nil @response.headers["ETag"]
  end

  def test_does_not_set_cache_for_new_records
    get :not_persisted
    assert_nil @response.headers["Last-Modified"]
    assert_equal "<xml />", @response.body
    assert_equal 200, @response.status
  end
end