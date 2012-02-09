require File.expand_path('test_helper', File.dirname(__FILE__))

class Malarz
  def self.human_name; 'Painter'; end

  def to_param
    self.slug
  end
end

class PaintersController < InheritedResources::Base
  defaults :instance_name => 'malarz', :collection_name => 'malarze',
           :resource_class => Malarz, :route_prefix => nil,
           :finder => :find_by_slug
end

class DefaultsTest < ActionController::TestCase
  tests PaintersController

  def setup
    @controller.stubs(:resource_url).returns('/')
    @controller.stubs(:collection_url).returns('/')
  end

  def test_expose_all_painters_as_instance_variable
    Malarz.expects(:scoped).returns([mock_painter])
    get :index
    assert_equal [mock_painter], assigns(:malarze)
  end

  def test_expose_the_requested_painter_on_show
    Malarz.expects(:find_by_slug).with('forty_two').returns(mock_painter)
    get :show, :id => 'forty_two'
    assert_equal mock_painter, assigns(:malarz)
  end

  def test_expose_a_new_painter
    Malarz.expects(:new).returns(mock_painter)
    get :new
    assert_equal mock_painter, assigns(:malarz)
  end

  def test_expose_the_requested_painter_on_edit
    Malarz.expects(:find_by_slug).with('forty_two').returns(mock_painter)
    get :edit, :id => 'forty_two'
    assert_response :success
    assert_equal mock_painter, assigns(:malarz)
  end

  def test_expose_a_newly_create_painter_when_saved_with_success
    Malarz.expects(:new).with({'these' => 'params'}).returns(mock_painter(:save => true))
    post :create, :malarz => {:these => 'params'}
    assert_equal mock_painter, assigns(:malarz)
  end

  def test_update_the_requested_object
    Malarz.expects(:find_by_slug).with('forty_two').returns(mock_painter)
    mock_painter.expects(:update_attributes).with({'these' => 'params'}).returns(true)
    put :update, :id => 'forty_two', :malarz => {:these => 'params'}
    assert_equal mock_painter, assigns(:malarz)
  end

  def test_the_requested_painter_is_destroyed
    Malarz.expects(:find_by_slug).with('forty_two').returns(mock_painter)
    mock_painter.expects(:destroy)
    delete :destroy, :id => 'forty_two'
    assert_equal mock_painter, assigns(:malarz)
  end

  protected
    def mock_painter(stubs={})
      @mock_painter ||= mock(stubs)
    end
end

class Professor
  def self.human_name; 'Einstein'; end
end
module University; end
class University::ProfessorsController < InheritedResources::Base
  defaults :finder => :find_by_slug
end

class DefaultsNamespaceTest < ActionController::TestCase
  tests University::ProfessorsController

  def setup
    @controller.stubs(:resource_url).returns('/')
    @controller.stubs(:collection_url).returns('/')
  end

  def test_expose_all_professors_as_instance_variable
    Professor.expects(:scoped).returns([mock_professor])
    get :index
    assert_equal [mock_professor], assigns(:professors)
  end

  def test_expose_the_requested_painter_on_show
    Professor.expects(:find_by_slug).with('forty_two').returns(mock_professor)
    get :show, :id => 'forty_two'
    assert_equal mock_professor, assigns(:professor)
  end

  def test_expose_a_new_painter
    Professor.expects(:new).returns(mock_professor)
    get :new
    assert_equal mock_professor, assigns(:professor)
  end

  def test_expose_the_requested_painter_on_edit
    Professor.expects(:find_by_slug).with('forty_two').returns(mock_professor)
    get :edit, :id => 'forty_two'
    assert_response :success
    assert_equal mock_professor, assigns(:professor)
  end

  def test_expose_a_newly_create_professor_when_saved_with_success
    Professor.expects(:new).with({'these' => 'params'}).returns(mock_professor(:save => true))
    post :create, :professor => {:these => 'params'}
    assert_equal mock_professor, assigns(:professor)
  end

  def test_update_the_professor
    Professor.expects(:find_by_slug).with('forty_two').returns(mock_professor)
    mock_professor.expects(:update_attributes).with({'these' => 'params'}).returns(true)
    put :update, :id => 'forty_two', :professor => {:these => 'params'}
    assert_equal mock_professor, assigns(:professor)
  end

  def test_the_requested_painter_is_destroyed
    Professor.expects(:find_by_slug).with('forty_two').returns(mock_professor)
    mock_professor.expects(:destroy)
    delete :destroy, :id => 'forty_two'
    assert_equal mock_professor, assigns(:professor)
  end

  protected
    def mock_professor(stubs={})
      @mock_professor ||= mock(stubs)
    end
end

class Group
end
class AdminGroup
end
module Admin; end
class Admin::Group
end
class Admin::GroupsController < InheritedResources::Base
end
class NamespacedModelForNamespacedController < ActionController::TestCase
  tests Admin::GroupsController

  def test_that_it_picked_the_namespaced_model
    # make public so we can test it
    Admin::GroupsController.send(:public, *Admin::GroupsController.protected_instance_methods)
    assert_equal Admin::Group, @controller.resource_class
  end
end

class Role
end
class AdminRole
end
class Admin::RolesController < InheritedResources::Base
end
class TwoPartNameModelForNamespacedController < ActionController::TestCase
  tests Admin::RolesController

  def test_that_it_picked_the_camelcased_model
    # make public so we can test it
    Admin::RolesController.send(:public, *Admin::RolesController.protected_instance_methods)
    assert_equal AdminRole, @controller.resource_class
  end
end

class User
end
class Admin::UsersController < InheritedResources::Base
end
class TwoPartNameModelForNamespacedController < ActionController::TestCase
  tests Admin::UsersController

  def setup
    # make public so we can test it
    Admin::UsersController.send(:public, *Admin::UsersController.protected_instance_methods)
  end

  def test_that_it_picked_the_camelcased_model
    assert_equal User, @controller.resource_class
  end

  def test_that_it_got_the_rquest_params_right
    assert_equal 'user', @controller.resources_configuration[:self][:request_name]
  end
end
