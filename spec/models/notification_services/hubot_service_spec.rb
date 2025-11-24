# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationServices::HubotService, type: :model do
  it "should send a notification to Hubot" do
    notice = Fabricate :notice
    notification_service = Fabricate :hubot_notification_service, app: notice.app
    problem = notice.problem

    expect(HTTParty).to receive(:post).with(notification_service.api_token, body: {message: an_instance_of(String), room: notification_service.room_id}).and_return(true)

    notification_service.create_notification(problem)
  end
end
