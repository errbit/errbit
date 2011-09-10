require 'spec_helper'

describe Mailer do
  context "Err Notification" do
    include EmailSpec::Helpers
    include EmailSpec::Matchers

    before do
      @notice = Factory(:notice, :message => "class < ActionController::Base")
      @email = Mailer.err_notification(@notice)
    end

    it "should html-escape the notice's message for the html part" do
      @email.should have_body_text("class &lt; ActionController::Base")
    end

    it "should inline css" do
      @email.should have_body_text '<td class="header" style="'
      # ('style' attribute is not present unless premailer works.)
    end
  end
end

