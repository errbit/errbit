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
      Factory(:deploy, :app => Factory(:app_with_watcher, :notify_on_deploys => true))
    end

    context 'when the app has resolve_errs_on_deploy set to false' do
      it 'should not resolve the apps errs' do
        app = Factory(:app, :resolve_errs_on_deploy => false)
        @problems = 3.times.map{Factory(:err, :problem => Factory(:problem, :resolved => false, :app => app))}
        Factory(:deploy, :app => app)
        app.reload.problems.none?{|problem| problem.resolved?}.should == true
      end
    end

    context 'when the app has resolve_errs_on_deploy set to true' do
      it 'should resolve the apps errs that were in the same environment' do
        app = Factory(:app, :resolve_errs_on_deploy => true)
        @prod_errs = 3.times.map{Factory(:problem, :resolved => false, :app => app, :environment => 'production')}
        @staging_errs = 3.times.map{Factory(:problem, :resolved => false, :app => app, :environment => 'staging')}
        Factory(:deploy, :app => app, :environment => 'production')
        @prod_errs.all?{|problem| problem.reload.resolved?}.should == true
        @staging_errs.all?{|problem| problem.reload.resolved?}.should == false
      end
    end

    context 'when the app has deploy notifications set to false' do
      it 'should not send an email notification' do
        Mailer.should_not_receive(:deploy_notification)
        Factory(:deploy, :app => Factory(:app_with_watcher, :notify_on_deploys => false))
      end
    end
  end

  it "should produce a shortened revision with 7 characters" do
    Deploy.new(:revision => "1234567890abcdef").short_revision.should == "1234567"
  end
end

