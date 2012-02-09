require File.expand_path('test_helper', File.dirname(__FILE__))

class Student
  extend ActiveModel::Naming
end

class ApplicationController < ActionController::Base
  include InheritedResources::DSL
end

class StudentsController < ApplicationController
  inherit_resources
  respond_to :html, :xml

  def edit
    edit! do |format|
      format.xml { render :text => 'Render XML' }
    end
  end

  def new
    @something = 'magical'
    new!
  end

  create!(:location => "http://test.host/") do |success, failure|
    success.html { render :text => "I won't redirect!" }
    failure.xml { render :text => "I shouldn't be rendered" }
  end

  update! do |success, failure|
    success.html { redirect_to(resource_url) }
    failure.html { render :text => "I won't render!" }
  end

  destroy! do |format|
    format.html { render :text => "Destroyed!" }
  end
end

class AliasesTest < ActionController::TestCase
  tests StudentsController

  def test_assignments_before_calling_alias
    Student.stubs(:new).returns(mock_student)
    get :new
    assert_response :success
    assert_equal 'magical', assigns(:something)
  end

  def test_controller_should_render_new
    Student.stubs(:new).returns(mock_student)
    get :new
    assert_response :success
    assert_equal 'New HTML', @response.body.strip
  end

  def test_expose_the_requested_user_on_edit
    Student.expects(:find).with('42').returns(mock_student)
    get :edit, :id => '42'
    assert_equal mock_student, assigns(:student)
    assert_response :success
  end

  def test_controller_should_render_edit
    Student.stubs(:find).returns(mock_student)
    get :edit
    assert_response :success
    assert_equal 'Edit HTML', @response.body.strip
  end

  def test_render_xml_when_it_is_given_as_a_block
    @request.accept = 'application/xml'
    Student.stubs(:find).returns(mock_student)
    get :edit
    assert_response :success
    assert_equal 'Render XML', @response.body
  end

  def test_is_not_redirected_on_create_with_success_if_success_block_is_given
    Student.stubs(:new).returns(mock_student(:save => true))
    @controller.stubs(:resource_url).returns('http://test.host/')
    post :create
    assert_response :success
    assert_equal "I won't redirect!", @response.body
  end

  def test_dumb_responder_quietly_receives_everything_on_failure
    @request.accept = 'text/html'
    Student.stubs(:new).returns(mock_student(:save => false, :errors => {:some => :error}))
    @controller.stubs(:resource_url).returns('http://test.host/')
    post :create
    assert_response :success
    assert_equal "New HTML", @response.body.strip
  end

  def test_html_is_the_default_when_only_xml_is_overwriten
    @request.accept = '*/*'
    Student.stubs(:new).returns(mock_student(:save => false, :errors => {:some => :error}))
    @controller.stubs(:resource_url).returns('http://test.host/')
    post :create
    assert_response :success
    assert_equal "New HTML", @response.body.strip
  end

  def test_wont_render_edit_template_on_update_with_failure_if_failure_block_is_given
    Student.stubs(:find).returns(mock_student(:update_attributes => false, :errors => { :fail => true }))
    put :update
    assert_response :success
    assert_equal "I won't render!", @response.body
  end

  def test_dumb_responder_quietly_receives_everything_on_success
    Student.stubs(:find).returns(mock_student(:update_attributes => true))
    @controller.stubs(:resource_url).returns('http://test.host/')
    put :update, :id => '42', :student => {:these => 'params'}
    assert_equal mock_student, assigns(:student)
  end

  def test_block_is_called_when_student_is_destroyed
    Student.stubs(:find).returns(mock_student(:destroy => true))
    delete :destroy
    assert_response :success
    assert_equal "Destroyed!", @response.body
  end

  def test_options_are_used_in_respond_with
    @request.accept = "application/xml"
    mock_student = mock_student(:save => true, :to_xml => "XML")
    Student.stubs(:new).returns(mock_student)

    # Bug in mocha does not accept strings on respond_to
    mock_student.singleton_class.class_eval do
      def respond_to?(method, *)
        method == "to_xml" || super
      end
    end

    post :create
    assert_equal "http://test.host/", @response.location
  end

  protected
    def mock_student(expectations={})
      @mock_student ||= begin
        student = mock(expectations.except(:errors))
        student.stubs(:class).returns(Student)
        student.stubs(:errors).returns(expectations.fetch(:errors, {})) 
        student
      end
    end
end

