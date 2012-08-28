require 'spec_helper'

describe ErrsHelper do
  describe '#truncated_err_message' do
    it 'is html safe' do
      problem = double('problem', :message => '#<NoMethodError: ...>')
      truncated = helper.truncated_err_message(problem)
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
        Errbit::Config.stub(:gravatar_size).and_return(48)
        Errbit::Config.stub(:gravatar_default).and_return('identicon')
      end

      it "should render image_tag with correct alt and src" do
        expected = "<img alt=\"#{email}\" src=\"#{base_url}?d=identicon&amp;s=48\" />"
        helper.gravatar_tag(email).should eq(expected)
      end

      it "should override :s" do
        expected = "<img alt=\"#{email}\" src=\"#{base_url}?d=identicon&amp;s=64\" />"
        helper.gravatar_tag(email, :s => 64).should eq(expected)
      end

      it "should override :d" do
        expected = "<img alt=\"#{email}\" src=\"#{base_url}?d=retro&amp;s=48\" />"
        helper.gravatar_tag(email, :d => 'retro').should eq(expected)
      end

      it "should override alt" do
        expected = "<img alt=\"gravatar\" src=\"#{base_url}?d=identicon&amp;s=48\" />"
        helper.gravatar_tag(email, :alt => 'gravatar').should eq(expected)
      end

      it "should pass other options to image_tag" do
        expected = "<img align=\"left\" alt=\"#{email}\" src=\"#{base_url}?d=identicon&amp;s=48\" />"
        helper.gravatar_tag(email, :align => :left).should eq(expected)
      end
    end
  end
end
