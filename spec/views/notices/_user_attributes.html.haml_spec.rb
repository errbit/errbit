# frozen_string_literal: true

require "rails_helper"

RSpec.describe "notices/_user_attributes.html.haml", type: :view do
  describe "autolink" do
    let(:notice) do
      user_attributes = {"foo" => {"bar" => "https://example.com"}}

      create(:notice, user_attributes: user_attributes)
    end

    it "renders table with user attributes" do
      assign :app, notice.err.app

      render "notices/user_attributes", user_attributes: notice.user_attributes

      expect(rendered).to have_link("https://example.com")
    end
  end
end
