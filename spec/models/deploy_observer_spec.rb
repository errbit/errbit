require 'spec_helper'

describe "Callback on Deploy" do
  context 'when a Deploy is saved' do
    context 'and the app should notify on deploys' do
      it 'should send an email notification' do
        expect(Mailer).to receive(:deploy_notification).
          and_return(double('email', :deliver => true))
        Fabricate(:deploy, :app => Fabricate(:app_with_watcher, :notify_on_deploys => true))
      end
    end

    context 'and the app is not set to notify on deploys' do
      it 'should not send an email notification' do
        expect(Mailer).to_not receive(:deploy_notification)
        Fabricate(:deploy, :app => Fabricate(:app_with_watcher, :notify_on_deploys => false))
      end
    end
  end
end
