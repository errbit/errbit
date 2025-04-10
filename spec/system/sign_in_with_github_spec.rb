# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in with GitHub", type: :system do
  # before { driven_by(:selenium_chrome_headless) }

  before { driven_by(:my_headless_chrome) }

  # https://bibwild.wordpress.com/2024/10/08/getting-rspec-capybara-browser-console-output-for-failed-tests/
  # hacky way to inject browser logs into failure message for failed ones
  after(:each) do |example|
    if example.exception
      browser_logs = page.driver.browser.logs.get(:browser).collect { |log| "#{log.level}: #{log.message}" }

      if browser_logs.present?
        # pretty hacky internal way to get browser logs into
        # existing long-form failure message, when that is
        # stored in exception associated with assertion failure
        new_exception = example.exception.class.new("#{example.exception.message}\n\nBrowser console:\n\n#{browser_logs.join("\n")}\n")
        new_exception.set_backtrace(example.exception.backtrace)

        example.display_exception = new_exception
      end
    end
  end

  context "sign in via GitHub with recognized user" do
    let!(:user) { Fabricate(:user, github_login: "nashby") }

    before { expect(Errbit::Config).to receive(:github_authentication).and_return(true).twice }

    before { OmniAuth.config.mock_auth[:github] = Faker::Omniauth.github(name: "nashby") }

    after { OmniAuth.config.mock_auth[:github] = nil }

    it "is expected to sign in user via GitHub" do
      visit root_path

      click_link "Sign in with GitHub"

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", kind: "GitHub"))
    end
  end

  context "reject unrecognized user" do
    it "is expected to reject unrecognized user" do
      visit root_path

      click_link "Sign in with GitHub"

      expect(page).to have_content("There are no authorized users with GitHub login")
    end
  end
end
