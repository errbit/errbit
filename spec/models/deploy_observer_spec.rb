require 'spec_helper'

describe DeployObserver do
  context 'when a Deploy is saved' do
    context 'and the app should notify on deploys' do
      it 'should send an email notification' do
        Mailer.should_receive(:deploy_notification).
          and_return(double('email', :deliver => true))
        Fabricate(:deploy, :app => Fabricate(:app_with_watcher, :notify_on_deploys => true))
      end
    end

    context 'and the app is not set to notify on deploys' do
      it 'should not send an email notification' do
        Mailer.should_not_receive(:deploy_notification)
        Fabricate(:deploy, :app => Fabricate(:app_with_watcher, :notify_on_deploys => false))
      end
    end
  end
end
