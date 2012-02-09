require File.expand_path('test_helper', File.dirname(__FILE__))

class GreatSchool
end

class Professor
  def self.human_name; 'Professor'; end
end

class ProfessorsController < InheritedResources::Base
  belongs_to :school, :parent_class => GreatSchool, :instance_name => :great_school,
                      :finder => :find_by_title!, :param => :school_title
end

class CustomizedBelongsToTest < ActionController::TestCase
  tests ProfessorsController

  def setup
    GreatSchool.expects(:find_by_title!).with('nice').returns(mock_school(:professors => Professor))
    @controller.stubs(:resource_url).returns('/')
    @controller.stubs(:collection_url).returns('/')
  end

  def test_expose_the_requested_school_with_chosen_instance_variable_on_index
    Professor.stubs(:scoped).returns([mock_professor])
    get :index, :school_title => 'nice'
    assert_equal mock_school, assigns(:great_school)
  end

  def test_expose_the_requested_school_with_chosen_instance_variable_on_show
    Professor.stubs(:find).returns(mock_professor)
    get :show, :school_title => 'nice'
    assert_equal mock_school, assigns(:great_school)
  end

  def test_expose_the_requested_school_with_chosen_instance_variable_on_new
    Professor.stubs(:build).returns(mock_professor)
    get :new, :school_title => 'nice'
    assert_equal mock_school, assigns(:great_school)
  end

  def test_expose_the_requested_school_with_chosen_instance_variable_on_edit
    Professor.stubs(:find).returns(mock_professor)
    get :edit, :school_title => 'nice'
    assert_equal mock_school, assigns(:great_school)
  end

  def test_expose_the_requested_school_with_chosen_instance_variable_on_create
    Professor.stubs(:build).returns(mock_professor(:save => true))
    post :create, :school_title => 'nice'
    assert_equal mock_school, assigns(:great_school)
  end

  def test_expose_the_requested_school_with_chosen_instance_variable_on_update
    Professor.stubs(:find).returns(mock_professor(:update_attributes => true))
    put :update, :school_title => 'nice'
    assert_equal mock_school, assigns(:great_school)
  end

  def test_expose_the_requested_school_with_chosen_instance_variable_on_destroy
    Professor.stubs(:find).returns(mock_professor(:destroy => true))
    delete :destroy, :school_title => 'nice'
    assert_equal mock_school, assigns(:great_school)
  end

  protected

    def mock_school(stubs={})
      @mock_school ||= mock(stubs)
    end

    def mock_professor(stubs={})
      @mock_professor ||= mock(stubs)
    end
end

