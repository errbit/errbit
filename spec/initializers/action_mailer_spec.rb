describe "initializers/action_mailer" do
  def load_initializer
    load File.join(Rails.root, "config", "initializers", "action_mailer.rb")
  end

  after do
    ActionMailer::Base.delivery_method = :test
  end

  describe "delivery method" do
    it "sets the delivery method to :smtp" do
      allow(Errbit::Config).to receive(:email_delivery_method).and_return(:smtp)
      load_initializer

      expect(ActionMailer::Base.delivery_method).to be(:smtp)
    end

    it "sets the delivery method to :sendmail" do
      allow(Errbit::Config).to receive(:email_delivery_method).and_return(:sendmail)
      load_initializer

      expect(ActionMailer::Base.delivery_method).to be(:sendmail)
    end
  end

  describe "smtp settings" do
    it "lets smtp settings be set" do
      allow(Errbit::Config).to receive(:email_delivery_method).and_return(:smtp)
      allow(Errbit::Config).to receive(:smtp_address).and_return("smtp.somedomain.com")
      allow(Errbit::Config).to receive(:smtp_port).and_return(998)
      allow(Errbit::Config).to receive(:smtp_authentication).and_return(:login)
      allow(Errbit::Config).to receive(:smtp_user_name).and_return("my-username")
      allow(Errbit::Config).to receive(:smtp_password).and_return("my-password")
      allow(Errbit::Config).to receive(:smtp_domain).and_return("someotherdomain.com")
      allow(Errbit::Config).to receive(:smtp_enable_starttls_auto).and_return(true)
      allow(Errbit::Config).to receive(:smtp_openssl_verify_mode).and_return("peer")
      load_initializer

      expect(ActionMailer::Base.smtp_settings).to eq(
        address:              "smtp.somedomain.com",
        port:                 998,
        authentication:       :login,
        user_name:            "my-username",
        password:             "my-password",
        domain:               "someotherdomain.com",
        enable_starttls_auto: true,
        openssl_verify_mode:  "peer"
      )
    end
  end
end
