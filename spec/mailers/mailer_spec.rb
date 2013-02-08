require 'spec_helper'

describe Mailer do
  context "Err Notification" do
    include EmailSpec::Helpers
    include EmailSpec::Matchers

    let(:notice)  { Fabricate(:notice, :message => "class < ActionController::Base") }
    let!(:email)  { Mailer.err_notification(notice).deliver }

    it "should send the email" do
      ActionMailer::Base.deliveries.size.should == 1
    end

    it "should html-escape the notice's message for the html part" do
      email.should have_body_text("class &lt; ActionController::Base")
    end

    it "should have inline css" do
      email.should have_body_text('<p class="backtrace" style="')
    end

    context 'with a very long message' do
      let(:notice)  { Fabricate(:notice, :message => 6.times.collect{|a| "0123456789" }.join('')) }
      it "should truncate the long message" do
        email.subject.should =~ / \d{47}\.{3}$/
      end
    end
  end
end

