require File.expand_path('test_helper', File.dirname(__FILE__))

class Subfaculty
end

class Speciality
end

module Plan
  class Group
  end

  class Education
  end
end

class GroupsController < InheritedResources::Base
  defaults :resource_class => Plan::Group, :finder => :find_by_slug
  belongs_to :subfaculty, :shallow => true do
    belongs_to :speciality
  end
end

class EducationsController < InheritedResources::Base
  defaults :resource_class => Plan::Education
  belongs_to :subfaculty, :shallow => true do
    belongs_to :speciality do
      belongs_to :group, :parent_class => Plan::Group,
                         :instance_name => :plan_group,
                         :param => :group_id,
                         :finder => :find_by_slug
    end
  end
end

class NestedModelWithShallowTest < ActionController::TestCase
  tests GroupsController

  def setup
    mock_speciality.expects(:subfaculty).returns(mock_subfaculty)
    mock_subfaculty.expects(:to_param).returns('13')

    Subfaculty.expects(:find).with('13').returns(mock_subfaculty)
    mock_subfaculty.expects(:specialities).returns(Speciality)
    mock_speciality.expects(:groups).returns(Plan::Group)

    @controller.stubs(:resource_url).returns('/')
    @controller.stubs(:collection_url).returns('/')
  end

  def test_assigns_subfaculty_and_speciality_and_group_on_edit
    should_find_parents
    get :edit, :id => 'forty_two'

    assert_equal mock_subfaculty, assigns(:subfaculty)
    assert_equal mock_speciality, assigns(:speciality)
    assert_equal mock_group, assigns(:group)
  end

  def test_expose_a_newly_create_group_with_speciality
    Speciality.expects(:find).with('37').twice.returns(mock_speciality)
    Plan::Group.expects(:build).with({'these' => :params}).returns(mock_group(:save => true))
    post :create, :speciality_id => '37', :group => {:these => :params}
    assert_equal mock_group, assigns(:group)
  end

  def test_expose_a_update_group_with_speciality
    should_find_parents
    mock_group.expects(:update_attributes).with('these' => :params).returns(true)
    post :update, :id => 'forty_two', :group => {:these => :params}
    assert_equal mock_group, assigns(:group)
  end

  protected
    def should_find_parents
      Plan::Group.expects(:find_by_slug).with('forty_two').returns(mock_group)
      mock_group.expects(:speciality).returns(mock_speciality)
      mock_speciality.expects(:to_param).returns('37')
      Plan::Group.expects(:find_by_slug).with('forty_two').returns(mock_group)
      Speciality.expects(:find).with('37').returns(mock_speciality)
    end

    def mock_group(stubs={})
      @mock_group ||= mock(stubs)
    end

    def mock_speciality(stubs={})
      @mock_speciality ||= mock(stubs)
    end

    def mock_subfaculty(stubs={})
      @mock_subfaculty ||= mock(stubs)
    end
end

class TwoNestedModelWithShallowTest < ActionController::TestCase
  tests EducationsController

  def setup
    mock_speciality.expects(:subfaculty).returns(mock_subfaculty)
    mock_subfaculty.expects(:to_param).returns('13')
    Subfaculty.expects(:find).with('13').returns(mock_subfaculty)
    mock_subfaculty.expects(:specialities).returns(Speciality)
    mock_speciality.expects(:groups).returns(Plan::Group)

    @controller.stubs(:resource_url).returns('/')
    @controller.stubs(:collection_url).returns('/')
  end

  def test_assigns_subfaculty_and_speciality_and_group_on_new
    should_find_parents
    get :new, :group_id => 'forty_two'

    assert_equal mock_subfaculty, assigns(:subfaculty)
    assert_equal mock_speciality, assigns(:speciality)
    assert_equal mock_group, assigns(:plan_group)
    assert_equal mock_education, assigns(:education)
  end


  protected
    def should_find_parents
      Plan::Group.expects(:find_by_slug).with('forty_two').returns(mock_group)
      mock_group.expects(:speciality).returns(mock_speciality)
      mock_group.expects(:educations).returns(mock_education)
      mock_education.expects(:build).returns(mock_education)
      mock_speciality.expects(:to_param).returns('37')
      Plan::Group.expects(:find_by_slug).with('forty_two').returns(mock_group)
      Speciality.expects(:find).with('37').returns(mock_speciality)
    end

    def mock_group(stubs={})
      @mock_group ||= mock(stubs)
    end

    def mock_education(stubs={})
      @mock_education ||= mock(stubs)
    end

    def mock_speciality(stubs={})
      @mock_speciality ||= mock(stubs)
    end

    def mock_subfaculty(stubs={})
      @mock_subfaculty ||= mock(stubs)
    end
end
