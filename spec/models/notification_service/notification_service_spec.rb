require 'spec_helper'

describe NotificationService do

  let(:notice) { Fabricate :notice }
  let(:notification_service) { Fabricate :notification_service, :app => notice.app }
  let(:problem) { notice.problem }

  it "it should use http by default in #problem_url" do
    notification_service.problem_url(problem).should start_with 'http://'
  end

  it "it should use the protocol value specified in the config in #problem_url" do
    Errbit::Config.protocol = 'https'
    notification_service.problem_url(problem).should start_with 'https://'
  end

end
