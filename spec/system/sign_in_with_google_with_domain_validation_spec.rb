# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sign in with Google with domain validation", type: :system do
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

  before { expect(Errbit::Config).to receive(:google_authentication).and_return(true).at_least(:once).times }

  before { expect(Errbit::Config).to receive(:google_auto_provision).and_return(true) }

  before { expect(Errbit::Config).to receive(:google_authorized_domains).and_return("example.com").twice }

  context "create an account for recognized user if their account email is from a trusted domain" do
    before { OmniAuth.config.mock_auth[:google_oauth2] = Faker::Omniauth.google(email: "me@example.com", uid: "123456789") }

    after { OmniAuth.config.mock_auth[:google_oauth2] = nil }

    it "is expected to create an account" do
      visit root_path

      click_link "Sign in with Google"

      expect(page).to have_content(I18n.t("devise.omniauth_callbacks.success", kind: "Google"))
    end
  end

  context "don't create an account for user if their account email is from an unauthorized domain" do
    before { OmniAuth.config.mock_auth[:google_oauth2] = Faker::Omniauth.google(email: "me@mail.example.com", uid: "123456789") }

    after { OmniAuth.config.mock_auth[:google_oauth2] = nil }

    it "is expected to not create an account" do
      visit root_path

      click_link "Sign in with Google"

      expect(page).to have_text(I18n.t("devise.google_login.domain_unauthorized"))
    end
  end
end
