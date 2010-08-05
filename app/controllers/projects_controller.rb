class ProjectsController < ApplicationController
  
  def index
    @projects = Project.all
  end
  
  def show
    @project = Project.find(params[:id])
    @errs  = @project.errs.paginate
  end
  
  def new
    @project = Project.new
    @project.watchers.build
  end
  
  def edit
    @project = Project.find(params[:id])
    @project.watchers.build if @project.watchers.none?
  end
  
  def create
    @project = Project.new(params[:project])
    
    if @project.save
      flash[:success] = 'Great success! Configure your project with the API key below'
      redirect_to project_path(@project)
    else
      render :new
    end
  end
  
  def update
    @project = Project.find(params[:id])
    
    if @project.update_attributes(params[:project])
      flash[:success] = "Good news everyone! '#{@project.name}' was successfully updated."
      redirect_to project_path(@project)
    else
      render :edit
    end
  end
  
  def destroy
    @project = Project.find(params[:id])
    @project.destroy
    flash[:success] = "'#{@project.name}' was successfully destroyed."
    redirect_to projects_path
  end
end
