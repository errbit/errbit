require 'spec_helper'

describe Mailer do
  context "Err Notification" do
    include EmailSpec::Helpers
    include EmailSpec::Matchers

    let(:notice)  { Fabricate(:notice, :message => "class < ActionController::Base") }

    before do
      notice.backtrace.lines.last.update_attributes(:file => "[PROJECT_ROOT]/path/to/file.js")
      notice.app.update_attributes :asset_host => "http://example.com"

      @email = Mailer.err_notification(notice).deliver
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

    it "should have links to source files" do
      @email.should have_body_text('<a href="http://example.com/path/to/file.js" target="_blank">path/to/file.js')
    end

    context 'with a very long message' do
      let(:notice)  { Fabricate(:notice, :message => 6.times.collect{|a| "0123456789" }.join('')) }
      it "should truncate the long message" do
        @email.subject.should =~ / \d{47}\.{3}$/
      end
    end
  end
end

