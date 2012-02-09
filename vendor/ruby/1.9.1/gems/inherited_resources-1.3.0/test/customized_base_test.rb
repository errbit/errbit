require File.expand_path('test_helper', File.dirname(__FILE__))

class Car
  extend ActiveModel::Naming
end

class CarsController < InheritedResources::Base
  respond_to :html

  protected

    def collection
      @cars ||= Car.get_all
    end

    def build_resource
      @car ||= Car.create_new(params[:car])
    end

    def resource
      @car ||= Car.get(params[:id])
    end

    def create_resource(resource)
      resource.save_successfully
    end

    def update_resource(resource, attributes)
      resource.update_successfully(*attributes)
    end

    def destroy_resource(resource)
      resource.destroy_successfully
    end
end

module CarTestHelper
  def setup
    @controller          = CarsController.new
    @controller.request  = @request  = ActionController::TestRequest.new
    @controller.response = @response = ActionController::TestResponse.new
    @controller.stubs(:car_url).returns("/")
  end

  protected
    def mock_car(expectations={})
      @mock_car ||= begin
        car = mock(expectations.except(:errors))
        car.stubs(:class).returns(Car)
        car.stubs(:errors).returns(expectations.fetch(:errors, {}))
        car
      end
    end
end

class IndexActionCustomizedBaseTest < ActionController::TestCase
  include CarTestHelper

  def test_expose_all_users_as_instance_variable
    Car.expects(:get_all).returns([mock_car])
    get :index
    assert_equal [mock_car], assigns(:cars)
  end
end

class ShowActionCustomizedBaseTest < ActionController::TestCase
  include CarTestHelper

  def test_expose_the_requested_user
    Car.expects(:get).with('42').returns(mock_car)
    get :show, :id => '42'
    assert_equal mock_car, assigns(:car)
  end
end

class NewActionCustomizedBaseTest < ActionController::TestCase
  include CarTestHelper

  def test_expose_a_new_user
    Car.expects(:create_new).returns(mock_car)
    get :new
    assert_equal mock_car, assigns(:car)
  end
end

class EditActionCustomizedBaseTest < ActionController::TestCase
  include CarTestHelper

  def test_expose_the_requested_user
    Car.expects(:get).with('42').returns(mock_car)
    get :edit, :id => '42'
    assert_response :success
    assert_equal mock_car, assigns(:car)
  end
end

class CreateActionCustomizedBaseTest < ActionController::TestCase
  include CarTestHelper

  def test_expose_a_newly_create_user_when_saved_with_success
    Car.expects(:create_new).with({'these' => 'params'}).returns(mock_car(:save_successfully => true))
    post :create, :car => {:these => 'params'}
    assert_equal mock_car, assigns(:car)
  end

  def test_redirect_to_the_created_user
    Car.stubs(:create_new).returns(mock_car(:save_successfully => true))
    @controller.expects(:resource_url).returns('http://test.host/')
    post :create
    assert_redirected_to 'http://test.host/'
  end

  def test_render_new_template_when_user_cannot_be_saved
    Car.stubs(:create_new).returns(mock_car(:save_successfully => false, :errors => {:some => :error}))
    post :create
    assert_response :success
    assert_equal "New HTML", @response.body.strip
  end
end

class UpdateActionCustomizedBaseTest < ActionController::TestCase
  include CarTestHelper

  def test_update_the_requested_object
    Car.expects(:get).with('42').returns(mock_car)
    mock_car.expects(:update_successfully).with({'these' => 'params'}).returns(true)
    put :update, :id => '42', :car => {:these => 'params'}
    assert_equal mock_car, assigns(:car)
  end

  def test_redirect_to_the_created_user
    Car.stubs(:get).returns(mock_car(:update_successfully => true))
    @controller.expects(:resource_url).returns('http://test.host/')
    put :update
    assert_redirected_to 'http://test.host/'
  end

  def test_render_edit_template_when_user_cannot_be_saved
    Car.stubs(:get).returns(mock_car(:update_successfully => false, :errors => {:some => :error}))
    put :update
    assert_response :success
    assert_equal "Edit HTML", @response.body.strip
  end
end

class DestroyActionCustomizedBaseTest < ActionController::TestCase
  include CarTestHelper

  def test_the_requested_user_is_destroyed
    Car.expects(:get).with('42').returns(mock_car)
    mock_car.expects(:destroy_successfully)
    delete :destroy, :id => '42'
    assert_equal mock_car, assigns(:car)
  end

  def test_show_flash_message_when_user_can_be_deleted
    Car.stubs(:get).returns(mock_car(:destroy_successfully => true))
    delete :destroy
    assert_equal flash[:notice], 'Car was successfully destroyed.'
  end

  def test_show_flash_message_when_cannot_be_deleted
    Car.stubs(:get).returns(mock_car(:destroy_successfully => false, :errors => { :fail => true }))
    delete :destroy
    assert_equal flash[:alert], 'Car could not be destroyed.'
  end
end

