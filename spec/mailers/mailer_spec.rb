require 'spec_helper'

describe Mailer do
  context "Err Notification" do
    include EmailSpec::Helpers
    include EmailSpec::Matchers

    before do
      @notice = Factory(:notice, :message => "class < ActionController::Base")
      @email = Mailer.err_notification(@notice).deliver
    end

    it "should send the email" do
      ActionMailer::Base.deliveries.size.should == 1
    end

    it "should html-escape the notice's message for the html part" do
      @email.should have_body_text("class &lt; ActionController::Base")
    end

    it "should have inline css" do
      @email.should have_body_text('<p class="backtrace" style="')
    end
  end
end

