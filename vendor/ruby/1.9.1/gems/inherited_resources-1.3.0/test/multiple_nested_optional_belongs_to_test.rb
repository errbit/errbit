require File.expand_path('test_helper', File.dirname(__FILE__))

class Student; end
class Manager; end
class Employee; end

class Project
	def self.human_name; "Project"; end
end

class ProjectsController < InheritedResources::Base
	belongs_to :student, :manager, :employee, :optional => true
end

class MultipleNestedOptionalTest < ActionController::TestCase
	tests ProjectsController

	def setup
		@controller.stubs(:resource_url).returns('/')
		@controller.stubs(:collection_url).returns('/')
	end

	# INDEX
	def test_expose_all_projects_as_instance_variable_with_student
		Student.expects(:find).with('37').returns(mock_student)
		mock_student.expects(:projects).returns(Project)
		Project.expects(:scoped).returns([mock_project])
		get :index, :student_id => '37'
		assert_equal mock_student, assigns(:student)
		assert_equal [mock_project], assigns(:projects)
	end

	def test_expose_all_projects_as_instance_variable_with_manager
		Manager.expects(:find).with('38').returns(mock_manager)
		mock_manager.expects(:projects).returns(Project)
		Project.expects(:scoped).returns([mock_project])
		get :index, :manager_id => '38'
		assert_equal mock_manager, assigns(:manager)
		assert_equal [mock_project], assigns(:projects)
	end

	def test_expose_all_projects_as_instance_variable_with_employee
		Employee.expects(:find).with('666').returns(mock_employee)
		mock_employee.expects(:projects).returns(Project)
		Project.expects(:scoped).returns([mock_project])
		get :index, :employee_id => '666'
		assert_equal mock_employee, assigns(:employee)
		assert_equal [mock_project], assigns(:projects)
	end

	def test_expose_all_projects_as_instance_variable_with_manager_and_employee
		Manager.expects(:find).with('37').returns(mock_manager)
		mock_manager.expects(:employees).returns(Employee)
		Employee.expects(:find).with('42').returns(mock_employee)
		mock_employee.expects(:projects).returns(Project)
		Project.expects(:scoped).returns([mock_project])
		get :index, :manager_id => '37', :employee_id => '42'
		assert_equal mock_manager, assigns(:manager)
		assert_equal mock_employee, assigns(:employee)
		assert_equal [mock_project], assigns(:projects)
	end

	def test_expose_all_projects_as_instance_variable_without_parents
		Project.expects(:scoped).returns([mock_project])
		get :index
		assert_equal [mock_project], assigns(:projects)
	end

	# SHOW
	def test_expose_the_requested_project_with_student
		Student.expects(:find).with('37').returns(mock_student)
		mock_student.expects(:projects).returns(Project)
		Project.expects(:find).with('42').returns(mock_project)
		get :show, :id => '42', :student_id => '37'
		assert_equal mock_student, assigns(:student)
		assert_equal mock_project, assigns(:project)
	end

	def test_expose_the_requested_project_with_manager
		Manager.expects(:find).with('37').returns(mock_manager)
		mock_manager.expects(:projects).returns(Project)
		Project.expects(:find).with('42').returns(mock_project)
		get :show, :id => '42', :manager_id => '37'
		assert_equal mock_manager, assigns(:manager)
		assert_equal mock_project, assigns(:project)
	end

	def test_expose_the_requested_project_with_employee
		Employee.expects(:find).with('37').returns(mock_employee)
		mock_employee.expects(:projects).returns(Project)
		Project.expects(:find).with('42').returns(mock_project)
		get :show, :id => '42', :employee_id => '37'
		assert_equal mock_employee, assigns(:employee)
		assert_equal mock_project, assigns(:project)
	end

	def test_expose_the_requested_project_with_manager_and_employee
		Manager.expects(:find).with('37').returns(mock_manager)
		mock_manager.expects(:employees).returns(Employee)
		Employee.expects(:find).with('42').returns(mock_employee)
		mock_employee.expects(:projects).returns(Project)
		Project.expects(:find).with('13').returns(mock_project)
		get :show, :id => '13', :manager_id => '37', :employee_id => '42'
		assert_equal mock_manager, assigns(:manager)
		assert_equal mock_employee, assigns(:employee)
		assert_equal mock_project, assigns(:project)
	end

	def test_expose_the_requested_project_without_parents
		Project.expects(:find).with('13').returns(mock_project)
		get :show, :id => '13'
		assert_equal mock_project, assigns(:project)
	end

	# NEW
	def test_expose_a_new_project_with_student
		Student.expects(:find).with('37').returns(mock_student)
		mock_student.expects(:projects).returns(Project)
		Project.expects(:build).returns(mock_project)
		get :new, :student_id => '37'
		assert_equal mock_student, assigns(:student)
		assert_equal mock_project, assigns(:project)
	end

	def test_expose_a_new_project_with_manager
		Manager.expects(:find).with('37').returns(mock_manager)
		mock_manager.expects(:projects).returns(Project)
		Project.expects(:build).returns(mock_project)
		get :new, :manager_id => '37'
		assert_equal mock_manager, assigns(:manager)
		assert_equal mock_project, assigns(:project)
	end

	def test_expose_a_new_project_with_employee
		Employee.expects(:find).with('37').returns(mock_employee)
		mock_employee.expects(:projects).returns(Project)
		Project.expects(:build).returns(mock_project)
		get :new, :employee_id => '37'
		assert_equal mock_employee, assigns(:employee)
		assert_equal mock_project, assigns(:project)
	end

	def test_expose_a_new_project_with_manager_and_employee
		Manager.expects(:find).with('37').returns(mock_manager)
		mock_manager.expects(:employees).returns(Employee)
		Employee.expects(:find).with('42').returns(mock_employee)
		mock_employee.expects(:projects).returns(Project)
		Project.expects(:build).returns(mock_project)
		get :new, :manager_id => '37', :employee_id => '42'
		assert_equal mock_manager, assigns(:manager)
		assert_equal mock_employee, assigns(:employee)
		assert_equal mock_project, assigns(:project)
	end

	def test_expose_a_new_project_without_parents
		Project.expects(:new).returns(mock_project)
		get :new
		assert_equal mock_project, assigns(:project)
	end

	# EDIT
	def test_expose_the_requested_project_for_edition_with_student
		Student.expects(:find).with('37').returns(mock_student)
		mock_student.expects(:projects).returns(Project)
		Project.expects(:find).with('42').returns(mock_project)
		get :edit, :id => '42', :student_id => '37'
		assert_equal mock_student, assigns(:student)
		assert_equal mock_project, assigns(:project)
	end

	def test_expose_the_requested_project_for_edition_with_manager
		Manager.expects(:find).with('37').returns(mock_manager)
		mock_manager.expects(:projects).returns(Project)
		Project.expects(:find).with('42').returns(mock_project)
		get :edit, :id => '42', :manager_id => '37'
		assert_equal mock_manager, assigns(:manager)
		assert_equal mock_project, assigns(:project)
	end

	def test_expose_the_requested_project_for_edition_with_employee
		Employee.expects(:find).with('37').returns(mock_employee)
		mock_employee.expects(:projects).returns(Project)
		Project.expects(:find).with('42').returns(mock_project)
		get :edit, :id => '42', :employee_id => '37'
		assert_equal mock_employee, assigns(:employee)
		assert_equal mock_project, assigns(:project)
	end

	def test_expose_the_requested_project_for_edition_with_manager_and_employee
		Manager.expects(:find).with('37').returns(mock_manager)
		mock_manager.expects(:employees).returns(Employee)
		Employee.expects(:find).with('42').returns(mock_employee)
		mock_employee.expects(:projects).returns(Project)
		Project.expects(:find).with('13').returns(mock_project)
		get :edit, :id => '13', :manager_id => '37', :employee_id => '42'
		assert_equal mock_manager, assigns(:manager)
		assert_equal mock_employee, assigns(:employee)
		assert_equal mock_project, assigns(:project)
	end

	def test_expose_the_requested_project_for_edition_without_parents
		Project.expects(:find).with('13').returns(mock_project)
		get :edit, :id => '13'
		assert_equal mock_project, assigns(:project)
	end

	# CREATE
	def test_expose_a_newly_created_project_with_student
		Student.expects(:find).with('37').returns(mock_student)
		mock_student.expects(:projects).returns(Project)
		Project.expects(:build).with({ 'these' => 'params' }).returns(mock_project(:save => true))
		post :create, :student_id => '37', :project => { :these => 'params' }
		assert_equal mock_student, assigns(:student)
		assert_equal mock_project, assigns(:project)
	end

	def test_expose_a_newly_created_project_with_manager
		Manager.expects(:find).with('37').returns(mock_manager)
		mock_manager.expects(:projects).returns(Project)
		Project.expects(:build).with({ 'these' => 'params' }).returns(mock_project(:save => true))
		post :create, :manager_id => '37', :project => { :these => 'params' }
		assert_equal mock_manager, assigns(:manager)
		assert_equal mock_project, assigns(:project)
	end
	
	def test_expose_a_newly_created_project_with_employee
		Employee.expects(:find).with('37').returns(mock_employee)
		mock_employee.expects(:projects).returns(Project)
		Project.expects(:build).with({ 'these' => 'params' }).returns(mock_project(:save => true))
		post :create, :employee_id => '37', :project => { :these => 'params' }
		assert_equal mock_employee, assigns(:employee)
		assert_equal mock_project, assigns(:project)
	end

	def test_expose_a_newly_created_project_with_manager_and_employee
		Manager.expects(:find).with('37').returns(mock_manager)
		mock_manager.expects(:employees).returns(Employee)
		Employee.expects(:find).with('42').returns(mock_employee)
		mock_employee.expects(:projects).returns(Project)
		Project.expects(:build).with({ 'these' => 'params' }).returns(mock_project(:save => true))
		post :create, :manager_id => '37', :employee_id => '42', :project => { :these => 'params' }
		assert_equal mock_manager, assigns(:manager)
		assert_equal mock_employee, assigns(:employee)
		assert_equal mock_project, assigns(:project)
	end

	def test_expose_a_newly_created_project_without_parents
		Project.expects(:new).with({ 'these' => 'params' }).returns(mock_project(:save => true))
		post :create, :project => { :these => 'params' }
		assert_equal mock_project, assigns(:project)
	end

	# UPDATE
	def test_update_the_requested_project_with_student
		Student.expects(:find).with('37').returns(mock_student)
		mock_student.expects(:projects).returns(Project)
		Project.expects(:find).with('42').returns(mock_project)
		mock_project.expects(:update_attributes).with({ 'these' => 'params' }).returns(true)
		put :update, :id => '42', :student_id => '37', :project => { :these => 'params' }
		assert_equal mock_student, assigns(:student)
		assert_equal mock_project, assigns(:project)
	end

	def test_update_the_requested_project_with_manager
		Manager.expects(:find).with('37').returns(mock_manager)
		mock_manager.expects(:projects).returns(Project)
		Project.expects(:find).with('42').returns(mock_project)
		mock_project.expects(:update_attributes).with({ 'these' => 'params' }).returns(true)
		put :update, :id => '42', :manager_id => '37', :project => { :these => 'params' }
		assert_equal mock_manager, assigns(:manager)
		assert_equal mock_project, assigns(:project)
	end

	def test_update_the_requested_project_with_employee
		Employee.expects(:find).with('37').returns(mock_employee)
		mock_employee.expects(:projects).returns(Project)
		Project.expects(:find).with('42').returns(mock_project)
		mock_project.expects(:update_attributes).with({ 'these' => 'params' }).returns(true)
		put :update, :id => '42', :employee_id => '37', :project => { :these => 'params' }
		assert_equal mock_employee, assigns(:employee)
		assert_equal mock_project, assigns(:project)
	end

	def test_update_the_requested_project_with_manager_and_employee
		Manager.expects(:find).with('37').returns(mock_manager)
		mock_manager.expects(:employees).returns(Employee)
		Employee.expects(:find).with('13').returns(mock_employee)
		mock_employee.expects(:projects).returns(Project)
		Project.expects(:find).with('42').returns(mock_project)
		mock_project.expects(:update_attributes).with({ 'these' => 'params' }).returns(true)
		put :update, :id => '42', :manager_id => '37', :employee_id => '13', :project => { :these => 'params' }
		assert_equal mock_manager, assigns(:manager)
		assert_equal mock_employee, assigns(:employee)
		assert_equal mock_project, assigns(:project)
	end

	# DESTROY
	def test_the_requested_project_is_destroyed_with_student
		Student.expects(:find).with('37').returns(mock_student)
		mock_student.expects(:projects).returns(Project)
		Project.expects(:find).with('42').returns(mock_project)
		mock_project.expects(:destroy).returns(true)

		delete :destroy, :id => '42', :student_id => '37'
		assert_equal mock_student, assigns(:student)
		assert_equal mock_project, assigns(:project)
	end

	def test_the_requested_project_is_destroyed_with_manager
		Manager.expects(:find).with('37').returns(mock_manager)
		mock_manager.expects(:projects).returns(Project)
		Project.expects(:find).with('42').returns(mock_project)
		mock_project.expects(:destroy).returns(true)

		delete :destroy, :id => '42', :manager_id => '37'
		assert_equal mock_manager, assigns(:manager)
		assert_equal mock_project, assigns(:project)
	end

	def test_the_requested_project_is_destroyed_with_employee
		Employee.expects(:find).with('37').returns(mock_employee)
		mock_employee.expects(:projects).returns(Project)
		Project.expects(:find).with('42').returns(mock_project)
		mock_project.expects(:destroy).returns(true)

		delete :destroy, :id => '42', :employee_id => '37'
		assert_equal mock_employee, assigns(:employee)
		assert_equal mock_project, assigns(:project)
	end

	def test_the_requested_project_is_destroyed_with_manager_and_employee
		Manager.expects(:find).with('37').returns(mock_manager)
		mock_manager.expects(:employees).returns(Employee)
		Employee.expects(:find).with('13').returns(mock_employee)
		mock_employee.expects(:projects).returns(Project)
		Project.expects(:find).with('42').returns(mock_project)
		mock_project.expects(:destroy).returns(true)

		delete :destroy, :id => '42', :manager_id => '37', :employee_id => '13'
		assert_equal mock_manager, assigns(:manager)
		assert_equal mock_employee, assigns(:employee)
		assert_equal mock_project, assigns(:project)
	end

	def test_the_requested_project_is_destroyed_without_parents
		Project.expects(:find).with('42').returns(mock_project)
		mock_project.expects(:destroy).returns(true)

		delete :destroy, :id => '42'
		assert_equal mock_project, assigns(:project)
	end

	protected
	def mock_manager(stubs={})
		@mock_manager ||= mock(stubs)
	end

	def mock_employee(stubs={})
		@mock_employee ||= mock(stubs)
	end

	def mock_student(stubs={})
		@mock_student ||= mock(stubs)
	end

	def mock_project(stubs={})
		@mock_project ||= mock(stubs)
	end
end