require 'spec_helper'

describe Mailer do
  context "Err Notification" do
    include EmailSpec::Helpers
    include EmailSpec::Matchers

    it "should html-escape the notice's message for the html part" do
      @notice = Factory(:notice, :message => "class < ActionController::Base")
      @email = Mailer.err_notification(@notice)
      @email.should have_body_text("class &lt; ActionController::Base")
    end
  end
end

