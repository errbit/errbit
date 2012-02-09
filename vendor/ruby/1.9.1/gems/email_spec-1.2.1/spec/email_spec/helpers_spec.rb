require File.dirname(__FILE__) + '/../spec_helper'

describe EmailSpec::Helpers do
  include EmailSpec::Helpers
  describe "#parse_email_for_link" do
    it "properly finds links with text" do
      email = Mail.new(:body =>  %(<a href="/path/to/page">Click Here</a>))
      parse_email_for_link(email, "Click Here").should == "/path/to/page"
    end

    it "recognizes img alt properties as text" do
      email = Mail.new(:body => %(<a href="/path/to/page"><img src="http://host.com/images/image.gif" alt="an image" /></a>))
      parse_email_for_link(email, "an image").should == "/path/to/page"
    end

    it "causes a spec to fail if the body doesn't contain the text specified to click" do
      email = Mail.new(:body => "")
      lambda { parse_email_for_link(email, "non-existent text") }.should raise_error(  RSpec::Expectations::ExpectationNotMetError)
    end
  end

  describe "#set_current_email" do
    it "should cope with a nil email" do
      lambda do
        out = set_current_email(nil)
        out.should be_nil
        email_spec_hash[:current_email].should be_nil
      end.should_not raise_error
    end

    it "should cope with a real email" do
      email = Mail.new
      lambda do
        out = set_current_email(email)
        out.should == email
        email_spec_hash[:current_email].should == email
      end.should_not raise_error
    end

    shared_examples_for 'something that sets the current email for recipients' do
      before do
        @email = Mail.new(@recipient_type => 'dave@example.com')
      end

      it "should record that the email has been read for that recipient" do
        set_current_email(@email)
        email_spec_hash[:read_emails]['dave@example.com'].should include(@email)
      end

      it "should record that the email has been read for all the recipient of that type" do
        @email.send(@recipient_type) << 'dave_2@example.com'
        set_current_email(@email)
        email_spec_hash[:read_emails]['dave@example.com'].should include(@email)
        email_spec_hash[:read_emails]['dave_2@example.com'].should include(@email)
      end

      it "should record that the email is the current email for the recipient" do
        set_current_email(@email)
        email_spec_hash[:current_emails]['dave@example.com'].should == @email
      end

      it "should record that the email is the current email for all the recipients of that type" do
        @email.send(@recipient_type) << 'dave_2@example.com'
        set_current_email(@email)
        email_spec_hash[:current_emails]['dave@example.com'].should == @email
        email_spec_hash[:current_emails]['dave_2@example.com'].should == @email
      end

      it "should overwrite current email for the recipient with this one" do
        other_mail = Mail.new
        email_spec_hash[:current_emails]['dave@example.com'] = other_mail
        set_current_email(@email)
        email_spec_hash[:current_emails]['dave@example.com'].should == @email
      end

      it "should overwrite the current email for all the recipients of that type" do
        other_mail = Mail.new
        email_spec_hash[:current_emails]['dave@example.com'] = other_mail
        email_spec_hash[:current_emails]['dave_2@example.com'] = other_mail
        @email.send(@recipient_type) << 'dave_2@example.com'
        set_current_email(@email)
        email_spec_hash[:current_emails]['dave@example.com'].should == @email
        email_spec_hash[:current_emails]['dave_2@example.com'].should == @email
      end

      it "should not complain when the email has recipients of that type" do
        @email.send(:"#{@recipient_type}=", nil)
        lambda { set_current_email(@email) }.should_not raise_error
      end
    end

    describe "#request_uri(link)" do
      context "without query and anchor" do
        it "returns the path" do
          request_uri('http://www.path.se/to/page').should == '/to/page'
        end
      end

      context "with query and anchor" do
        it "returns the path and query and the anchor" do
          request_uri('http://www.path.se/to/page?q=adam#task').should == '/to/page?q=adam#task'
        end
      end

      context "with anchor" do
        it "returns the path and query and the anchor" do
          request_uri('http://www.path.se/to/page#task').should == '/to/page#task'
        end
      end
    end

    describe 'for mails with recipients in the to address' do
      before do
        @recipient_type = :to
      end

      it_should_behave_like 'something that sets the current email for recipients'
    end

    describe 'for mails with recipients in the cc address' do
      before do
        @recipient_type = :cc
      end

      it_should_behave_like 'something that sets the current email for recipients'
    end

    describe 'for mails with recipients in the bcc address' do
      before do
        @recipient_type = :bcc
      end

      it_should_behave_like 'something that sets the current email for recipients'
    end
  end

  describe '#open_email' do
    describe 'with subject' do
      shared_examples_for 'something that opens the email with subject' do
        before do
          @to = "jimmy_bean@yahoo.com"
          @email = Mail::Message.new(:to => @to, :subject => @subject)
          stub!(:mailbox_for).with(@to).and_return([@email])
        end

        it "should open the email with subject" do
          open_email(@to, :with_subject => @expected).should == @email
        end
      end

      describe 'simple string subject' do
        before do
          @subject  = 'This is a simple subject'
          @expected = 'a simple'
        end

        it_should_behave_like 'something that opens the email with subject'
      end

      describe 'string with regex sensitive characters' do
        before do
          @subject  = '[app name] Contains regex characters?'
          @expected = 'regex characters?'
        end

        it_should_behave_like 'something that opens the email with subject'
      end

      describe 'regular expression' do
        before do
          @subject = "This is a simple subject"
          @expected = /a simple/
        end

        it_should_behave_like 'something that opens the email with subject'
      end
    end

    describe 'with text' do
      shared_examples_for 'something that opens the email with text' do
        before do
          @to = "jimmy_bean@yahoo.com"
          @email = Mail::Message.new(:to => @to, :body => @body)
          stub!(:mailbox_for).with(@to).and_return([@email])
        end

        it "should open the email with text" do
          open_email(@to, :with_text => @text).should == @email
        end
      end

      describe 'simple string text' do
        before do
          @body = 'This is an email body that is very simple'
          @text = 'email body'
        end

        it_should_behave_like 'something that opens the email with text'
      end

      describe 'string with regex sensitive characters' do
        before do
          @body = 'This is an email body. It contains some [regex] characters?'
          @text = '[regex] characters?'
        end

        it_should_behave_like 'something that opens the email with text'
      end

      describe 'regular expression' do
        before do
          @body = 'This is an email body.'
          @text = /an\ email/
        end

        it_should_behave_like 'something that opens the email with text'
      end
    end
  end
end
