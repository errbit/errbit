require 'spec_helper'

describe ProjectsController do
  
  describe "GET /projects" do
    it 'finds all projects' do
      3.times { Factory(:project) }
      projects = Project.all
      get :index
      assigns(:projects).should == projects
    end
  end
  
  describe "GET /projects/:id" do
    it 'finds the project' do
      project = Factory(:project)
      get :show, :id => project.id
      assigns(:project).should == project
    end
  end
  
end
