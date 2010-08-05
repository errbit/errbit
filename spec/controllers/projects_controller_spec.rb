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
  
  describe "GET /projects/new" do
    it 'instantiates a new project with a prebuilt watcher' do
      get :new
      assigns(:project).should be_a(Project)
      assigns(:project).should be_new_record
      assigns(:project).watchers.should_not be_empty
    end
  end
  
  describe "GET /projects/:id/edit" do
    it 'finds the correct project' do
      project = Factory(:project)
      get :edit, :id => project.id
      assigns(:project).should == project
    end
  end
  
  describe "POST /projects" do
    before do
      @project = Factory(:project)
      Project.stub(:new).and_return(@project)
    end
    
    context "when the create is successful" do
      before do
        @project.should_receive(:save).and_return(true)
      end
      
      it "should redirect to the project page" do
        post :create, :project => {}
        response.should redirect_to(project_path(@project))
      end
      
      it "should display a message" do
        post :create, :project => {}
        request.flash[:success].should match(/success/)
      end
    end
    
    context "when the create is unsuccessful" do
      it "should render the new page" do
        @project.should_receive(:save).and_return(false)
        post :create, :project => {}
        response.should render_template(:new)
      end
    end
  end
  
  describe "PUT /projects/:id" do
    before do
      @project = Factory(:project)
      Project.stub(:find).with(@project.id).and_return(@project)
    end
    
    context "when the update is successful" do
      before do
        @project.should_receive(:update_attributes).and_return(true)
      end
      
      it "should redirect to the project page" do
        put :update, :id => @project.id, :project => {}
        response.should redirect_to(project_path(@project))
      end
      
      it "should display a message" do
        put :update, :id => @project.id, :project => {}
        request.flash[:success].should match(/success/)
      end
    end
    
    context "when the update is unsuccessful" do
      it "should render the edit page" do
        @project.should_receive(:update_attributes).and_return(false)
        put :update, :id => @project.id, :project => {}
        response.should render_template(:edit)
      end
    end
  end
  
  describe "DELETE /projects/:id" do
    before do
      @project = Factory(:project)
      Project.stub(:find).with(@project.id).and_return(@project)
    end
    
    it "should find the project" do
      delete :destroy, :id => @project.id
      assigns(:project).should == @project
    end
    
    it "should destroy the project" do
      @project.should_receive(:destroy)
      delete :destroy, :id => @project.id
    end
    
    it "should display a message" do
      delete :destroy, :id => @project.id
      request.flash[:success].should match(/success/)
    end
    
    it "should redirect to the projects page" do
      delete :destroy, :id => @project.id
      response.should redirect_to(projects_path)
    end
  end
  
end
