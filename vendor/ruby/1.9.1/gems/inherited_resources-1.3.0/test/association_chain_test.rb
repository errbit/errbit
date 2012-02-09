require File.expand_path('test_helper', File.dirname(__FILE__))

class Pet
  extend ActiveModel::Naming
end

class Puppet
  extend ActiveModel::Naming
end

class PetsController < InheritedResources::Base
  attr_accessor :current_user
  
  def edit
    @pet = 'new pet'
    edit!
  end

  protected
    def collection
      @pets ||= end_of_association_chain.all
    end

    def begin_of_association_chain
      @current_user
    end
end

class BeginOfAssociationChainTest < ActionController::TestCase
  tests PetsController

  def setup
    @controller.current_user = mock()
  end

  def test_begin_of_association_chain_is_called_on_index
    @controller.current_user.expects(:pets).returns(Pet)
    Pet.expects(:all).returns(mock_pet)
    get :index
    assert_response :success
    assert_equal 'Index HTML', @response.body.strip
  end

  def test_begin_of_association_chain_is_called_on_new
    @controller.current_user.expects(:pets).returns(Pet)
    Pet.expects(:build).returns(mock_pet)
    get :new
    assert_response :success
    assert_equal 'New HTML', @response.body.strip
  end

  def test_begin_of_association_chain_is_called_on_show
    @controller.current_user.expects(:pets).returns(Pet)
    Pet.expects(:find).with('47').returns(mock_pet)
    get :show, :id => '47'
    assert_response :success
    assert_equal 'Show HTML', @response.body.strip
  end

  def test_instance_variable_should_not_be_set_if_already_defined
    @controller.current_user.expects(:pets).never
    Pet.expects(:find).never
    get :edit
    assert_response :success
    assert_equal 'new pet', assigns(:pet)
  end

  def test_model_is_not_initialized_with_nil
    @controller.current_user.expects(:pets).returns(Pet)
    Pet.expects(:build).with({}).returns(mock_pet)
    get :new
    assert_equal mock_pet, assigns(:pet)
  end

  def test_begin_of_association_chain_is_included_in_chain
    @controller.current_user.expects(:pets).returns(Pet)
    Pet.expects(:build).with({}).returns(mock_pet)
    get :new
    assert_equal [@controller.current_user], @controller.send(:association_chain)
  end

  protected
    def mock_pet(stubs={})
      @mock_pet ||= mock(stubs)
    end

end

class PuppetsController < InheritedResources::Base
  optional_belongs_to :pet
end

class AssociationChainTest < ActionController::TestCase
  tests PuppetsController

  def setup
    @controller.stubs(:resource_url).returns('/')
    @controller.stubs(:collection_url).returns('/')
  end

  def test_parent_is_added_to_association_chain
    Pet.expects(:find).with('37').returns(mock_pet)
    mock_pet.expects(:puppets).returns(Puppet)
    Puppet.expects(:find).with('42').returns(mock_puppet)
    mock_puppet.expects(:destroy)
    delete :destroy, :id => '42', :pet_id => '37'
    assert_equal [mock_pet], @controller.send(:association_chain)
  end

  def test_parent_is_added_to_association_chain_if_not_available
    Puppet.expects(:find).with('42').returns(mock_puppet)
    mock_puppet.expects(:destroy)
    delete :destroy, :id => '42'
    assert_equal [], @controller.send(:association_chain)
  end

  protected
    def mock_pet(stubs={})
      @mock_pet ||= mock(stubs)
    end

    def mock_puppet(stubs={})
      @mock_puppet ||= mock(stubs)
    end
end
