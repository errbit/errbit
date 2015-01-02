require 'spec_helper'

describe NotificationService::KatoService do
  let(:notice) { Fabricate.build(:notice) }
  let(:problem) { notice.problem }
  let(:notification_service) { Fabricate :kato_notification_service, :app => notice.app }

  it "it should send a notification to Kato" do
    payload = {
      :from => 'Errbit',
      :renderer => 'markdown',
      :text => notification_service.format_message(problem),
      :color => 'red'
    }.to_json

    expect(HTTParty).to receive(:post).with(
      "https://api.kato.im/rooms/#{notification_service.api_token}/simple",
      :body => payload, :headers => {"Content-Type"=>"application/json"}
    ).and_return(true)

    notification_service.create_notification(problem)
  end
end
