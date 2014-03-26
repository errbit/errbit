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

    context 'and the app has and notification set' do
      it 'should send a notification' do
        noti_serv = Fabricate(:gtalk_notification_service)
        noti_serv.should_receive(:create_notification).once
        app = Fabricate(:app,
                        :notify_on_deploys => true,
                        :notification_service => noti_serv)
        Fabricate(:deploy, :app => app)
      end
    end

    context 'and the app does not have a notification set' do
      it 'should not send a notification' do
        noti_serv = Fabricate(:gtalk_notification_service)
        noti_serv.should_not_receive(:create_notification)
        app = Fabricate(:app,
                        :notify_on_deploys => false,
                        :notification_service => noti_serv)
        Fabricate(:deploy, :app => app)

      end
    end

  end
end
