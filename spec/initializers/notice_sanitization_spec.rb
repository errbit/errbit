# frozen_string_literal: true

require "rails_helper"

RSpec.describe "initializers/notice_sanitization" do
  def load_initializer
    load File.join(Rails.root, "config", "initializers", "notice_sanitization.rb")
  end

  it "warns when privacy sanitization is disabled" do
    allow(Errbit::Config).to receive(:sanitize_notice_data).and_return(false)

    expect(Rails.logger).to receive(:warn).with(
      "ERRBIT_SANITIZE_NOTICE_DATA=false. Sensitive notice data may be persisted for apps " \
      "that inherit the global setting. Configure app-level or client-side Airbrake filtering where possible."
    )

    load_initializer
  end

  it "does not warn when privacy sanitization is enabled" do
    allow(Errbit::Config).to receive(:sanitize_notice_data).and_return(true)

    expect(Rails.logger).not_to receive(:warn)

    load_initializer
  end
end
