require 'spec_helper'

describe ProblemsHelper do
  describe '#truncated_problem_message' do
    it 'is html safe' do
      problem = double('problem', :message => '#<NoMethodError: ...>')
      truncated = helper.truncated_problem_message(problem)
      truncated.should be_html_safe
      truncated.should_not include('<', '>')
    end
  end

  describe "#gravatar_tag" do
    let(:email) { "gravatar@example.com" }
    let(:email_hash) { Digest::MD5.hexdigest email }
    let(:base_url) { "http://www.gravatar.com/avatar/#{email_hash}" }

    context "default config" do
      before do
        Errbit::Config.stub(:use_gravatar).and_return(true)
        Errbit::Config.stub(:gravatar_default).and_return('identicon')
      end

      it "should render image_tag with correct alt and src" do
        expected = "<img alt=\"#{email}\" class=\"gravatar\" src=\"#{base_url}?d=identicon&amp;s=48\" />"
        helper.gravatar_tag(email, :s => 48).should eq(expected)
      end

      it "should override :d" do
        expected = "<img alt=\"#{email}\" class=\"gravatar\" src=\"#{base_url}?d=retro&amp;s=48\" />"
        helper.gravatar_tag(email, :d => 'retro', :s => 48).should eq(expected)
      end
    end

    context "no email" do
      it "should not render the tag" do
        helper.gravatar_tag(nil).should be_nil
      end
    end
  end

  describe "#gravatar_url" do
    context "no email" do
      let(:email) { nil }

      it "should return nil" do
        helper.gravatar_url(email).should be_nil
      end
    end

    context "without ssl" do
      let(:email) { "gravatar@example.com" }
      let(:email_hash) { Digest::MD5.hexdigest email }

      it "should return the http url" do
        helper.gravatar_url(email).should eq("http://www.gravatar.com/avatar/#{email_hash}?d=identicon")
      end
    end

    context "with ssl" do
      let(:email) { "gravatar@example.com" }
      let(:email_hash) { Digest::MD5.hexdigest email }

      it "should return the http url" do
        ActionController::TestRequest.any_instance.stub :ssl? => true
        helper.gravatar_url(email).should eq("https://secure.gravatar.com/avatar/#{email_hash}?d=identicon")
      end
    end
  end
end
