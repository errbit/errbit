require 'spec_helper'

describe Mailer do
  context "Err Notification" do
    include EmailSpec::Helpers
    include EmailSpec::Matchers

    let(:notice)  { Fabricate(:notice, :message => "class < ActionController::Base") }
    let!(:user)   { Fabricate(:admin) }

    before do
      notice.backtrace.lines.last.update_attributes(:file => "[PROJECT_ROOT]/path/to/file.js")
      notice.app.update_attributes(
        :asset_host => "http://example.com",
        :notify_all_users => true
      )
      notice.problem.update_attributes :notices_count => 3

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

    it "should have the error count in the subject" do
      @email.subject.should =~ /^\(3\) /
    end

    context 'with a very long message' do
      let(:notice)  { Fabricate(:notice, :message => 6.times.collect{|a| "0123456789" }.join('')) }
      it "should truncate the long message" do
        @email.subject.should =~ / \d{47}\.{3}$/
      end
    end
  end

  context "Comment Notification" do
    include EmailSpec::Helpers
    include EmailSpec::Matchers

    let!(:notice) { Fabricate(:notice) }
    let!(:comment) { Fabricate.build(:comment, :err => notice.problem) }
    let!(:watcher) { Fabricate(:watcher, :app => comment.app) }
    let(:recipients) { ['recipient@example.com', 'another@example.com']}

    before do
      comment.stub(:notification_recipients).and_return(recipients)
      Fabricate(:notice, :err => notice.err)
      @email = Mailer.comment_notification(comment).deliver
    end

    it "should send the email" do
      ActionMailer::Base.deliveries.size.should == 1
    end

    it "should be sent to comment notification recipients" do
      @email.to.should == recipients
    end

    it "should have the notices count in the body" do
      @email.should have_body_text("This err has occurred 2 times")
    end

    it "should have the comment body" do
      @email.should have_body_text(comment.body)
    end
  end
end
