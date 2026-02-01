# frozen_string_literal: true

require "rails_helper"

RSpec.describe "initializers/action_mailer" do
  def load_initializer
    load File.join(Rails.root, "config", "initializers", "action_mailer.rb")
  end

  after do
    ActionMailer::Base.delivery_method = :test
  end

  describe "delivery method" do
    it "sets the delivery method to :smtp" do
      Config.email.delivery_method = "smtp"

      load_initializer

      expect(ActionMailer::Base.delivery_method).to eq(:smtp)
    end

    it "sets the delivery method to :sendmail" do
      Config.email.delivery_method = "sendmail"

      load_initializer

      expect(ActionMailer::Base.delivery_method).to eq(:sendmail)
    end
  end

  describe "smtp settings" do
    it "lets smtp settings be set" do
      Config.email.delivery_method = "smtp"
      Config.smtp.settings.address = "smtp.somedomain.com"
      Config.smtp.settings.port = 998
      Config.smtp.settings.domain = "someotherdomain.com"
      Config.smtp.settings.user_name = "my-username"
      Config.smtp.settings.password = "my-password"
      Config.smtp.settings.authentication = "login"
      Config.smtp.settings.enable_starttls_auto = true
      Config.smtp.settings.openssl_verify_mode = "peer"

      load_initializer

      expect(ActionMailer::Base.smtp_settings).to eq(
        address: "smtp.somedomain.com",
        port: 998,
        domain: "someotherdomain.com",
        user_name: "my-username",
        password: "my-password",
        authentication: :login,
        enable_starttls_auto: true,
        openssl_verify_mode: "peer"
      )
    end
  end
end
