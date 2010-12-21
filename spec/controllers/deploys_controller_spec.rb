require 'spec_helper'

describe DeploysController do
  
  context 'POST #create' do
    before do
      @params = {
        'local_username' => 'john.doe',
        'scm_repository' => 'git@github.com/jdpace/errbit.git',
        'rails_env'      => 'production',
        'scm_revision'   => '19d77837eef37902cf5df7e4445c85f392a8d0d5', 
        'message'        => 'Because we want to'
      }
      @app = Factory(:app_with_watcher, :api_key => 'APIKEY')
    end
    
    it 'finds the app via the api key' do
      App.should_receive(:find_by_api_key!).with('APIKEY').and_return(@app)
      post :create, :deploy => @params, :api_key => 'APIKEY'
    end
    
    it 'creates a deploy' do
      App.stub(:find_by_api_key!).and_return(@app)
      @app.deploys.should_receive(:create!).
        with({
          :username     => 'john.doe',
          :environment  => 'production',
          :repository   => 'git@github.com/jdpace/errbit.git',
          :revision     => '19d77837eef37902cf5df7e4445c85f392a8d0d5',
          :message      => 'Because we want to'
        }).and_return(Factory(:deploy))
      post :create, :deploy => @params, :api_key => 'APIKEY'
    end
    
    it 'sends an email notification' do
      post :create, :deploy => @params, :api_key => 'APIKEY'
      email = ActionMailer::Base.deliveries.last
      email.to.should include(@app.watchers.first.email)
      email.subject.should == "[#{@app.name}] Deployed to production by john.doe"
    end
    
  end
  
end
