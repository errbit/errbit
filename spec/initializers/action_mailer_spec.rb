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
    it "sets the delivery method to smtp" do
      expect(Rails.configuration.errbit)
        .to receive(:email_delivery_method)
        .and_return("smtp")
        .at_least(:once)

      load_initializer

      expect(ActionMailer::Base.delivery_method).to eq(:smtp)
    end

    it "sets the delivery method to sendmail" do
      expect(Rails.configuration.errbit)
        .to receive(:email_delivery_method)
        .and_return("sendmail")
        .at_least(:once)

      load_initializer

      expect(ActionMailer::Base.delivery_method).to eq(:sendmail)
    end
  end

  describe "smtp settings" do
    it "lets smtp settings be set" do
      expect(Rails.configuration.errbit).to receive(:email_delivery_method).and_return("smtp").at_least(:once)
      expect(Rails.configuration.errbit).to receive(:smtp_address).and_return("smtp.somedomain.com")
      expect(Rails.configuration.errbit).to receive(:smtp_port).and_return(998)
      expect(Rails.configuration.errbit).to receive(:smtp_domain).and_return("someotherdomain.com")
      expect(Rails.configuration.errbit).to receive(:smtp_user_name).and_return("my-username")
      expect(Rails.configuration.errbit).to receive(:smtp_password).and_return("my-password")
      expect(Rails.configuration.errbit).to receive(:smtp_authentication).and_return(:login)
      expect(Rails.configuration.errbit).to receive(:smtp_enable_starttls_auto).and_return(true)
      expect(Rails.configuration.errbit).to receive(:smtp_openssl_verify_mode).and_return("peer")

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
