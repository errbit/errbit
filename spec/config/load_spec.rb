# frozen_string_literal: true

require "rails_helper"

RSpec.describe "config/load" do
  before do
    @original_config = Errbit::Config if Errbit.const_defined?(:Config, false)
  end

  def load_config_with(env)
    allow(ENV).to receive(:[]).and_return(nil)
    allow(ENV).to receive(:[]).with("GITHUB_URL").and_return("https://github.com")
    env.each do |key, value|
      allow(ENV).to receive(:[]).with(key).and_return(value)
    end

    Errbit.send(:remove_const, :Config) if Errbit.const_defined?(:Config, false)
    load Rails.root.join("config/load.rb")
  rescue
    restore_config
    raise
  end

  def restore_config
    Errbit.send(:remove_const, :Config) if Errbit.const_defined?(:Config, false)
    Errbit.const_set(:Config, @original_config) if @original_config
  end

  after { restore_config }

  it "loads typed application settings" do
    load_config_with(
      "ERRBIT_CONFIRM_ERR_ACTIONS" => "false",
      "ERRBIT_EMAIL_AT_NOTICES" => "1, 10, 100",
      "ERRBIT_NOTIFY_AT_NOTICES" => "0",
      "ERRBIT_PER_APP_EMAIL_AT_NOTICES" => "true",
      "ERRBIT_PER_APP_NOTIFY_AT_NOTICES" => "false",
      "GITHUB_ACCESS_SCOPE" => "repo, user",
      "GITHUB_AUTHENTICATION" => "true",
      "GITHUB_ORG_ID" => "123",
      "GOOGLE_AUTHENTICATION" => "false",
      "GOOGLE_AUTO_PROVISION" => "true",
      "GOOGLE_AUTHORIZED_DOMAINS" => "example.com, example.org",
      "SMTP_PORT" => "2525",
      "SMTP_ENABLE_STARTTLS_AUTO" => "false",
      "DEVISE_MODULES" => "database_authenticatable, recoverable"
    )

    expect(Errbit::Config.confirm_err_actions).to be(false)
    expect(Errbit::Config.email_at_notices).to eq([1, 10, 100])
    expect(Errbit::Config.notify_at_notices).to eq([0])
    expect(Errbit::Config.per_app_email_at_notices).to be(true)
    expect(Errbit::Config.per_app_notify_at_notices).to be(false)
    expect(Errbit::Config.github_access_scope).to eq(["repo", "user"])
    expect(Errbit::Config.github_authentication).to be(true)
    expect(Errbit::Config.github_org_id).to eq(123)
    expect(Errbit::Config.google_authentication).to be(false)
    expect(Errbit::Config.google_auto_provision).to be(true)
    expect(Errbit::Config.google_authorized_domains).to eq(["example.com", "example.org"])
    expect(Errbit::Config.smtp_port).to eq(2525)
    expect(Errbit::Config.smtp_enable_starttls_auto).to be(false)
    expect(Errbit::Config.devise_modules).to eq(["database_authenticatable", "recoverable"])
  end

  it "rejects an invalid typed setting" do
    expect do
      load_config_with("ERRBIT_EMAIL_AT_NOTICES" => "1, invalid, 100")
    end.to raise_error(ArgumentError, /ERRBIT_EMAIL_AT_NOTICES must contain an integer/)
  end
end
