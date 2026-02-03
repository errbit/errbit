# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProblemsHelper, type: :helper do
  describe "#auto_link_format" do
    it "handles links with target and wraps paragraph" do
      expect(
        helper.auto_link_format("Goto https://errbit.com/ and say hello to team@errbit.invalid")
      ).to eq("<p>Goto <a target=\"_blank\" href=\"https://errbit.com/\">https://errbit.com/</a> and say hello to <a target=\"_blank\" href=\"mailto:team@errbit.invalid\">team@errbit.invalid</a></p>")
    end

    it "sanitizes body of html tags" do
      expect(helper.auto_link_format("Hello, <b>World!</b>")).to eq("<p>Hello, World!</p>")
    end
  end

  describe "#gravatar_tag" do
    let(:email) { "gravatar@example.com" }
    let(:email_hash) { Digest::MD5.hexdigest(email) }
    let(:base_url) { "https://secure.gravatar.com/avatar/#{email_hash}" }

    context "default config" do
      before do
        Rails.configuration.errbit.use_gravatar = true
      end

      it "should render image_tag with correct alt and src" do
        expected = "<img alt=\"#{email}\" class=\"gravatar\" src=\"#{base_url}?d=identicon&amp;s=48\" />"
        expect(helper.gravatar_tag(email, s: 48)).to eq(expected)
      end

      it "should override :d" do
        expected = "<img alt=\"#{email}\" class=\"gravatar\" src=\"#{base_url}?d=retro&amp;s=48\" />"
        expect(helper.gravatar_tag(email, d: "retro", s: 48)).to eq(expected)
      end
    end

    context "no email" do
      it "should not render the tag" do
        expect(helper.gravatar_tag(nil)).to eq(nil)
      end
    end
  end

  describe "#gravatar_url" do
    context "no email" do
      let(:email) { nil }

      it "should return nil" do
        expect(helper.gravatar_url(email)).to eq(nil)
      end
    end

    context "with email" do
      before do
        Rails.configuration.errbit.use_gravatar = true
      end

      let(:email) { "gravatar@example.com" }
      let(:email_hash) { Digest::MD5.hexdigest(email) }

      it "should return the https url" do
        expect(helper.gravatar_url(email)).to eq("https://secure.gravatar.com/avatar/#{email_hash}?d=identicon")
      end
    end
  end
end
