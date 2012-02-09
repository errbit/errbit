require File.expand_path('test_helper', File.dirname(__FILE__))

# This test file is instead to test the how controller flow and actions
# using a belongs_to association. This is done using mocks a la rspec.
#
class Store
  extend ActiveModel::Naming
end

class Manager
  extend ActiveModel::Naming
#  def self.human_name; 'Manager'; end
end

class ManagersController < InheritedResources::Base
  belongs_to :store, :singleton => true
end

class SingletonTest < ActionController::TestCase
  tests ManagersController

  def setup
    @controller.stubs(:resource_url).returns('/')
    @controller.stubs(:collection_url).returns('/')
  end

  def test_expose_the_requested_manager_on_show
    Store.expects(:find).with('37').returns(mock_store)
    mock_store.expects(:manager).returns(mock_manager)
    get :show, :store_id => '37'
    assert_equal mock_store, assigns(:store)
    assert_equal mock_manager, assigns(:manager)
  end

  def test_expose_a_new_manager_on_new
    Store.expects(:find).with('37').returns(mock_store)
    mock_store.expects(:build_manager).returns(mock_manager)
    get :new, :store_id => '37'
    assert_equal mock_store, assigns(:store)
    assert_equal mock_manager, assigns(:manager)
  end

  def test_expose_the_requested_manager_on_edit
    Store.expects(:find).with('37').returns(mock_store)
    mock_store.expects(:manager).returns(mock_manager)
    get :edit, :store_id => '37'
    assert_equal mock_store, assigns(:store)
    assert_equal mock_manager, assigns(:manager)
    assert_response :success
  end

  def test_expose_a_newly_create_manager_on_create
    Store.expects(:find).with('37').returns(mock_store)
    mock_store.expects(:build_manager).with({'these' => 'params'}).returns(mock_manager(:save => true))
    post :create, :store_id => '37', :manager => {:these => 'params'}
    assert_equal mock_store, assigns(:store)
    assert_equal mock_manager, assigns(:manager)
  end

  def test_update_the_requested_object_on_update
    Store.expects(:find).with('37').returns(mock_store(:manager => mock_manager))
    mock_manager.expects(:update_attributes).with({'these' => 'params'}).returns(true)
    put :update, :store_id => '37', :manager => {:these => 'params'}
    assert_equal mock_store, assigns(:store)
    assert_equal mock_manager, assigns(:manager)
  end

  def test_the_requested_manager_is_destroyed_on_destroy
    Store.expects(:find).with('37').returns(mock_store)
    mock_store.expects(:manager).returns(mock_manager)
    @controller.expects(:parent_url).returns('http://test.host/')
    mock_manager.expects(:destroy)
    delete :destroy, :store_id => '37'
    assert_equal mock_store, assigns(:store)
    assert_equal mock_manager, assigns(:manager)
  end

  protected
    def mock_store(stubs={})
      @mock_store ||= mock(stubs)
    end

    def mock_manager(stubs={})
      @mock_manager ||= mock(stubs)
    end
end
