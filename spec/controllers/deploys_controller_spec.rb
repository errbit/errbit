require 'spec_helper'

describe DeploysController do
  
  context 'POST #create' do
    before do
      @params = {
        'local_username' => 'john.doe',
        'scm_repository' => 'git@github.com/jdpace/hypnotoad.git',
        'rails_env'      => 'production',
        'scm_revision'   => '19d77837eef37902cf5df7e4445c85f392a8d0d5'
      }
      @project = Factory(:project_with_watcher, :api_key => 'ALLGLORYTOTHEHYPNOTOAD')
    end
    
    it 'finds the project via the api key' do
      Project.should_receive(:find_by_api_key!).with('ALLGLORYTOTHEHYPNOTOAD').and_return(@project)
      post :create, :deploy => @params, :api_key => 'ALLGLORYTOTHEHYPNOTOAD'
    end
    
    it 'creates a deploy' do
      Project.stub(:find_by_api_key!).and_return(@project)
      @project.deploys.should_receive(:create!).
        with({
          :username     => 'john.doe',
          :environment  => 'production',
          :repository   => 'git@github.com/jdpace/hypnotoad.git',
          :revision     => '19d77837eef37902cf5df7e4445c85f392a8d0d5'
        }).and_return(Factory(:deploy))
      post :create, :deploy => @params, :api_key => 'ALLGLORYTOTHEHYPNOTOAD'
    end
    
    it 'sends an email notification', :focused => true do
      post :create, :deploy => @params, :api_key => 'ALLGLORYTOTHEHYPNOTOAD'
      email = ActionMailer::Base.deliveries.last
      email.to.should include(@project.watchers.first.email)
      email.subject.should == "[#{@project.name}] Deployed to production by john.doe"
    end
    
  end
  
end