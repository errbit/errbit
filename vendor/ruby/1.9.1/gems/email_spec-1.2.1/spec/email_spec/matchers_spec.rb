require File.dirname(__FILE__) + '/../spec_helper'

describe EmailSpec::Matchers do
  include EmailSpec::Matchers

  class MatcherMatch
    def initialize(object_to_test_match)
      @object_to_test_match = object_to_test_match
    end

    def description
      "match when provided #{@object_to_test_match.inspect}"
    end

    def matches?(matcher)
      @matcher = matcher
      matcher.matches?(@object_to_test_match)
    end

    def failure_message
      "expected #{@matcher.inspect} to match when provided #{@object_to_test_match.inspect}, but it did not"
    end

    def negative_failure_message
      "expected #{@matcher.inspect} not to match when provided #{@object_to_test_match.inspect}, but it did"
    end
  end

  def match(object_to_test_match)
    if object_to_test_match.is_a?(Regexp)
      super # delegate to rspec's built in 'match' matcher
    else
      MatcherMatch.new(object_to_test_match)
    end
  end

  describe "#reply_to" do
    it "should match when the email is set to deliver to the specified address" do
      email = Mail::Message.new(:reply_to => ["test@gmail.com"])
      reply_to("test@gmail.com").should match(email)
    end

    it "should match given a name and address" do
      email = Mail::Message.new(:reply_to => ["test@gmail.com"])
      reply_to("David Balatero <test@gmail.com>").should match(email)
    end

    it "should give correct failure message when the email is not set to deliver to the specified address" do
      matcher = reply_to("jimmy_bean@yahoo.com")
      matcher.matches?(Mail::Message.new(:reply_to => ['freddy_noe@yahoo.com']).with_inspect_stub)
      matcher.failure_message.should == %{expected email to reply to "jimmy_bean@yahoo.com", but it replied to "freddy_noe@yahoo.com"}
    end

  end

  describe "#deliver_to" do
    it "should match when the email is set to deliver to the specified address" do
      email = Mail::Message.new(:to => "jimmy_bean@yahoo.com")

      deliver_to("jimmy_bean@yahoo.com").should match(email)
    end

    it "should match when the email is set to deliver to the specified name and address" do
      email = Mail::Message.new(:to => "Jimmy Bean <jimmy_bean@yahoo.com>")
      deliver_to("Jimmy Bean <jimmy_bean@yahoo.com>").should match(email)
    end

    it "should match when a list of emails is exact same as all of the email's recipients" do
      email = Mail::Message.new(:to => ["james@yahoo.com", "karen@yahoo.com"])

      deliver_to("karen@yahoo.com", "james@yahoo.com").should match(email)
      deliver_to("karen@yahoo.com").should_not match(email)
    end

    it "should match when an array of emails is exact same as all of the email's recipients" do
      addresses = ["james@yahoo.com", "karen@yahoo.com"]
      email = Mail::Message.new(:to => addresses)
      deliver_to(addresses).should match(email)
    end
    
    it "should match when the names and email addresses match in any order" do
      addresses = ["James <james@yahoo.com>", "Karen <karen@yahoo.com>"]
      email = Mail::Message.new(:to => addresses.reverse)
      deliver_to(addresses).should match(email)
    end

    it "should use the passed in objects :email method if not a string" do
      email = Mail::Message.new(:to => "jimmy_bean@yahoo.com")
      user = mock("user", :email => "jimmy_bean@yahoo.com")

      deliver_to(user).should match(email)
    end

    it "should not match when the email does not have a recipient" do
      email = Mail::Message.new(:to => nil)
      deliver_to("jimmy_bean@yahoo.com").should_not match(email)
    end

    it "should not match when the email addresses match but the names do not" do
      email = Mail::Message.new(:to => "Jimmy Bean <jimmy_bean@yahoo.com>")
      deliver_to("Freddy Noe <jimmy_bean@yahoo.com>").should_not match(email)
    end

    it "should not match when the names match but the email addresses do not" do
      email = Mail::Message.new(:to => "Jimmy Bean <jimmy_bean@yahoo.com>")
      deliver_to("Jimmy Bean <freddy_noe@yahoo.com>").should_not match(email)
    end

    it "should give correct failure message when the email is not set to deliver to the specified address" do
      matcher = deliver_to("jimmy_bean@yahoo.com")
      message = Mail::Message.new(:to => 'freddy_noe@yahoo.com')
      message.stub(:inspect).and_return("email")
      matcher.matches?(message)
      matcher.failure_message.should == %{expected email to deliver to ["jimmy_bean@yahoo.com"], but it delivered to ["freddy_noe@yahoo.com"]}
    end

  end

  describe "#deliver_from" do
    it "should match when the email is set to deliver from the specified address" do
      email = Mail::Message.new(:from => "jimmy_bean@yahoo.com")
      deliver_from("jimmy_bean@yahoo.com").should match(email)
    end

    it "should match when the email is set to deliver from the specified name and address" do
      email = Mail::Message.new(:from => "Jimmy Bean <jimmy_bean@yahoo.com>")
      deliver_from("Jimmy Bean <jimmy_bean@yahoo.com>").should match(email)
    end

    it "should not match when the email does not have a sender" do
      email = Mail::Message.new(:from => nil)
      deliver_from("jimmy_bean@yahoo.com").should_not match(email)
    end

    it "should not match when the email addresses match but the names do not" do
      email = Mail::Message.new(:from => "Jimmy Bean <jimmy_bean@yahoo.com>")
      deliver_from("Freddy Noe <jimmy_bean@yahoo.com>").should_not match(email)
    end

    it "should not match when the names match but the email addresses do not" do
      email = Mail::Message.new(:from => "Jimmy Bean <jimmy_bean@yahoo.com>")
      deliver_from("Jimmy Bean <freddy_noe@yahoo.com>").should_not match(email)
    end

    it "should not match when the email is not set to deliver from the specified address" do
      email = Mail::Message.new(:from => "freddy_noe@yahoo.com")
      deliver_from("jimmy_bean@yahoo.com").should_not match(email)
    end

    it "should give correct failure message when the email is not set to deliver from the specified address" do
      matcher = deliver_from("jimmy_bean@yahoo.com")
      matcher.matches?(Mail::Message.new(:from => "freddy_noe@yahoo.com"))
      matcher.failure_message.should =~ /expected .+ to deliver from "jimmy_bean@yahoo\.com", but it delivered from "freddy_noe@yahoo\.com"/
    end

  end

  describe "#bcc_to" do

    it "should match when the email is set to deliver to the specidied address" do
      email = Mail::Message.new(:bcc => "jimmy_bean@yahoo.com")

      bcc_to("jimmy_bean@yahoo.com").should match(email)
    end

    it "should match when a list of emails is exact same as all of the email's recipients" do
      email = Mail::Message.new(:bcc => ["james@yahoo.com", "karen@yahoo.com"])

      bcc_to("karen@yahoo.com", "james@yahoo.com").should match(email)
      bcc_to("karen@yahoo.com").should_not match(email)
    end

    it "should match when an array of emails is exact same as all of the email's recipients" do
      addresses = ["james@yahoo.com", "karen@yahoo.com"]
      email = Mail::Message.new(:bcc => addresses)
      bcc_to(addresses).should match(email)
    end

    it "should use the passed in objects :email method if not a string" do
      email = Mail::Message.new(:bcc => "jimmy_bean@yahoo.com")
      user = mock("user", :email => "jimmy_bean@yahoo.com")

      bcc_to(user).should match(email)
    end

  end

  describe "#cc_to" do

    it "should match when the email is set to deliver to the specified address" do
      email = Mail::Message.new(:cc => "jimmy_bean@yahoo.com")

      cc_to("jimmy_bean@yahoo.com").should match(email)
    end

    it "should match when a list of emails is exact same as all of the email's recipients" do
      email = Mail::Message.new(:cc => ["james@yahoo.com", "karen@yahoo.com"])

      cc_to("karen@yahoo.com", "james@yahoo.com").should match(email)
      cc_to("karen@yahoo.com").should_not match(email)
    end

    it "should match when an array of emails is exact same as all of the email's recipients" do
      addresses = ["james@yahoo.com", "karen@yahoo.com"]
      email = Mail::Message.new(:cc => addresses)
      cc_to(addresses).should match(email)
    end

    it "should use the passed in objects :email method if not a string" do
      email = Mail::Message.new(:cc => "jimmy_bean@yahoo.com")
      user = mock("user", :email => "jimmy_bean@yahoo.com")

      cc_to(user).should match(email)
    end

  end

  describe "#have_subject" do

    describe "when regexps are used" do

      it "should match when the subject matches regexp" do
        email = Mail::Message.new(:subject => ' -- The Subject --')

        have_subject(/The Subject/).should match(email)
        have_subject(/foo/).should_not match(email)
      end

      it "should have a helpful description" do
        matcher = have_subject(/foo/)
        matcher.matches?(Mail::Message.new(:subject => "bar"))

        matcher.description.should == "have subject matching /foo/"
      end

      it "should offer helpful failing messages" do
        matcher = have_subject(/foo/)
        matcher.matches?(Mail::Message.new(:subject => "bar"))

        matcher.failure_message.should == 'expected the subject to match /foo/, but did not.  Actual subject was: "bar"'
      end

      it "should offer helpful negative failing messages" do
        matcher = have_subject(/b/)
        matcher.matches?(Mail::Message.new(:subject => "bar"))

        matcher.negative_failure_message.should == 'expected the subject not to match /b/ but "bar" does match it.'
      end
    end

    describe "when strings are used" do
      it "should match when the subject equals the passed in string exactly" do
        email = Mail::Message.new(:subject => 'foo')

        have_subject("foo").should match(email)
        have_subject(" - foo -").should_not match(email)
      end

      it "should have a helpful description" do
        matcher = have_subject("foo")
        matcher.matches?(Mail::Message.new(:subject => "bar"))

        matcher.description.should == 'have subject of "foo"'
      end

      it "should offer helpful failing messages" do
        matcher = have_subject("foo")
        matcher.matches?(Mail::Message.new(:subject => "bar"))

        matcher.failure_message.should == 'expected the subject to be "foo" but was "bar"'
      end

      it "should offer helpful negative failing messages" do
        matcher = have_subject("bar")
        matcher.matches?(Mail::Message.new(:subject => "bar"))

        matcher.negative_failure_message.should == 'expected the subject not to be "bar" but was'
      end
    end
  end

  describe "#include_email_with_subject" do
    
    describe "when regexps are used" do
      
      it "should match when any email's subject matches passed in regexp" do
        emails = [Mail::Message.new(:subject => "foobar"), Mail::Message.new(:subject => "bazqux")]
        
        include_email_with_subject(/foo/).should match(emails)
        include_email_with_subject(/quux/).should_not match(emails)
      end

      it "should have a helpful description" do
        matcher = include_email_with_subject(/foo/)
        matcher.matches?([])
        
        matcher.description.should == 'include email with subject matching /foo/'
      end

      it "should offer helpful failing messages" do
        matcher = include_email_with_subject(/foo/)
        matcher.matches?([Mail::Message.new(:subject => "bar")])
        
        matcher.failure_message.should == 'expected at least one email to have a subject matching /foo/, but none did. Subjects were ["bar"]'
      end

      it "should offer helpful negative failing messages" do
        matcher = include_email_with_subject(/foo/)
        matcher.matches?([Mail::Message.new(:subject => "foo")])
        
        matcher.negative_failure_message.should == 'expected no email to have a subject matching /foo/ but found at least one. Subjects were ["foo"]'
      end
    end
    
    describe "when strings are used" do
      it "should match when any email's subject equals passed in subject exactly" do
        emails = [Mail::Message.new(:subject => "foobar"), Mail::Message.new(:subject => "bazqux")]
        
        include_email_with_subject("foobar").should match(emails)
        include_email_with_subject("foo").should_not match(emails)
      end
      
      it "should have a helpful description" do
        matcher = include_email_with_subject("foo")
        matcher.matches?([])
        
        matcher.description.should == 'include email with subject of "foo"'
      end
      
      it "should offer helpful failing messages" do
        matcher = include_email_with_subject("foo")
        matcher.matches?([Mail::Message.new(:subject => "bar")])
        
        matcher.failure_message.should == 'expected at least one email to have the subject "foo" but none did. Subjects were ["bar"]'
      end
      
      it "should offer helpful negative failing messages" do
        matcher = include_email_with_subject("foo")
        matcher.matches?([Mail::Message.new(:subject => "foo")])
        
        matcher.negative_failure_message.should == 'expected no email with the subject "foo" but found at least one. Subjects were ["foo"]'
      end
    end
  end

  describe "#have_body_text" do
    describe "when regexps are used" do
      it "should match when the body matches regexp" do
        email = Mail::Message.new(:body => 'foo bar baz')

        have_body_text(/bar/).should match(email)
        have_body_text(/qux/).should_not match(email)
      end

      it "should have a helpful description" do
        matcher = have_body_text(/qux/)
        matcher.matches?(Mail::Message.new(:body => 'foo bar baz'))
        
        matcher.description.should == 'have body matching /qux/'
      end

      it "should offer helpful failing messages" do
        matcher = have_body_text(/qux/)
        matcher.matches?(Mail::Message.new(:body => 'foo bar baz'))
        
        matcher.failure_message.should == 'expected the body to match /qux/, but did not.  Actual body was: "foo bar baz"'
      end

      it "should offer helpful negative failing messages" do
        matcher = have_body_text(/bar/)
        matcher.matches?(Mail::Message.new(:body => 'foo bar baz'))

        matcher.negative_failure_message.should == 'expected the body not to match /bar/ but "foo bar baz" does match it.'
      end
    end
    
    describe "when strings are used" do
      it "should match when the body includes the text" do
        email = Mail::Message.new(:body => 'foo bar baz')
        
        have_body_text('bar').should match(email)
        have_body_text('qux').should_not match(email)
      end
      
      it "should have a helpful description" do
        matcher = have_body_text('qux')
        matcher.matches?(Mail::Message.new(:body => 'foo bar baz'))
        
        matcher.description.should == 'have body including "qux"'
      end
      
      it "should offer helpful failing messages" do
        matcher = have_body_text('qux')
        matcher.matches?(Mail::Message.new(:body => 'foo bar baz'))
        
        matcher.failure_message.should == 'expected the body to contain "qux" but was "foo bar baz"'
      end
      
      it "should offer helpful negative failing messages" do
        matcher = have_body_text('bar')
        matcher.matches?(Mail::Message.new(:body => 'foo bar baz'))
        
        matcher.negative_failure_message.should == 'expected the body not to contain "bar" but was "foo bar baz"'
      end
    end

    describe "when dealing with multipart messages" do
      it "should look at the html part" do
        email = Mail.new do
          text_part do
            body "This is text"
          end
          html_part do
            body "This is html"
          end
        end
        have_body_text(/This is html/).should match(email)
        have_body_text(/This is text/).should_not match(email)
      end
    end
  end

  describe "#have_header" do
    describe "when regexps are used" do
      it "should match when header matches passed in regexp" do
        email = Mail::Message.new(:content_type => "text/html")
        
        have_header(:content_type, /text/).should match(email)
        have_header(:foo, /text/).should_not match(email)
        have_header(:content_type, /bar/).should_not match(email)
      end

      it "should have a helpful description" do
        matcher = have_header(:content_type, /bar/)
        matcher.matches?(Mail::Message.new(:content_type => "text/html"))
        
        matcher.description.should == 'have header content_type with value matching /bar/'
      end

      it "should offer helpful failing messages" do
        matcher = have_header(:content_type, /bar/)
        matcher.matches?(Mail::Message.new(:content_type => "text/html"))
        
        matcher.failure_message.should == 'expected the headers to include \'content_type\' with a value matching /bar/ but they were {"content-type"=>"text/html"}'
      end

      it "should offer helpful negative failing messages" do
        matcher = have_header(:content_type, /text/)
        matcher.matches?(Mail::Message.new(:content_type => "text/html"))
        
        matcher.negative_failure_message.should == 'expected the headers not to include \'content_type\' with a value matching /text/ but they were {"content-type"=>"text/html"}'
      end
    end
    
    describe "when strings are used" do
      it "should match when header equals passed in value exactly" do
        email = Mail::Message.new(:content_type => "text/html")
        
        have_header(:content_type, 'text/html').should match(email)
        have_header(:foo, 'text/html').should_not match(email)
        have_header(:content_type, 'text').should_not match(email)
      end
      
      it "should have a helpful description" do
        matcher = have_header(:content_type, 'text')
        matcher.matches?(Mail::Message.new(:content_type => "text/html"))
        
        matcher.description.should == 'have header content_type: text'
      end
      
      it "should offer helpful failing messages" do
        matcher = have_header(:content_type, 'text')
        matcher.matches?(Mail::Message.new(:content_type => "text/html"))
        
        matcher.failure_message.should == 'expected the headers to include \'content_type: text\' but they were {"content-type"=>"text/html"}'
      end
      
      it "should offer helpful negative failing messages" do
        matcher = have_header(:content_type, 'text/html')
        matcher.matches?(Mail::Message.new(:content_type => "text/html"))
        
        matcher.negative_failure_message == 'expected the headers not to include \'content_type: text/html\' but they were {:content_type=>"text/html"}'
      end
    end
  end
end
