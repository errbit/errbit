require 'spec_helper'

describe Deploy do
  
  context 'validations' do
    it 'requires a username' do
      deploy = Factory.build(:deploy, :username => nil)
      deploy.should_not be_valid
      deploy.errors[:username].should include("can't be blank")
    end
    
    it 'requires an environment' do
      deploy = Factory.build(:deploy, :environment => nil)
      deploy.should_not be_valid
      deploy.errors[:environment].should include("can't be blank")
    end
  end
  
  context 'being created' do
    it 'should send an email notification' do
      Mailer.should_receive(:deploy_notification).
        and_return(mock('email', :deliver => true))
      Factory(:deploy, :project => Factory(:project_with_watcher))
    end
    
    context 'when the project has resolve_errs_on_deploy set to false' do
      it 'should not resolve the projects errs' do
        project = Factory(:project, :resolve_errs_on_deploy => false)
        @errs = 3.times.inject([]) {|errs,_| errs << Factory(:err, :resolved => false, :project => project)}
        Factory(:deploy, :project => project)
        project.reload.errs.none?{|err| err.resolved?}.should == true
      end
    end
    
    context 'when the project has resolve_errs_on_deploy set to true' do
      it 'should not resolve the projects errs' do
        project = Factory(:project, :resolve_errs_on_deploy => true)
        @errs = 3.times.inject([]) {|errs,_| errs << Factory(:err, :resolved => false, :project => project)}
        Factory(:deploy, :project => project)
        project.reload.errs.all?{|err| err.resolved?}.should == true
      end
    end
  end
  
end
