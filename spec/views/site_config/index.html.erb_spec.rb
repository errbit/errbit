# frozen_string_literal: true

require "rails_helper"

RSpec.describe "site_config/index.html.erb", type: :view do
  let(:config) { SiteConfig.document }

  before do
    assign(:config, config)

    render
  end

  it "renders a form to edit site configuration" do
    expect(rendered).to have_selector("form", count: 1)
    expect(rendered).to have_selector("input[type='submit']")
  end

  it "has fields for notice fingerprinter attributes" do
    fingerprinter_fields = [
      "error_class",
      "message",
      "backtrace_lines",
      "component",
      "action",
      "environment_name"
    ]

    fingerprinter_fields.each do |field|
      expect(rendered).to have_field("site_config_notice_fingerprinter_attributes_#{field}")
    end
  end
end
