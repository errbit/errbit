describe 'initializers/action_mailer' do
  def load_initializer
    load File.join(Rails.root, 'config', 'initializers', 'action_mailer.rb')
  end

  before do
    @delivery_method = ActionMailer::Base.delivery_method
    @sendmail_settings = ActionMailer::Base.sendmail_settings
    @smtp_settings = ActionMailer::Base.smtp_settings
  end

  after do
    ActionMailer::Base.delivery_method = @delivery_method
    ActionMailer::Base.sendmail_settings = @sendmail_settings
    ActionMailer::Base.smtp_settings = @smtp_settings
  end

  describe 'delivery method' do
    it 'sets the delivery method to :smtp' do
      allow(Errbit::Config).to receive(:email_delivery_method).and_return(:smtp)
      load_initializer

      expect(ActionMailer::Base.delivery_method).to be(:smtp)
    end

    it 'sets the delivery method to :sendmail' do
      allow(Errbit::Config).to receive(:email_delivery_method).and_return(:sendmail)
      load_initializer

      expect(ActionMailer::Base.delivery_method).to be(:sendmail)
    end
  end

  describe 'smtp settings' do
    it 'lets smtp settings be set' do
      allow(Errbit::Config).to receive(:email_delivery_method).and_return(:smtp)
      allow(Errbit::Config).to receive(:smtp_address).and_return('smtp.somedomain.com')
      allow(Errbit::Config).to receive(:smtp_port).and_return(998)
      allow(Errbit::Config).to receive(:smtp_authentication).and_return(:login)
      allow(Errbit::Config).to receive(:smtp_user_name).and_return('my-username')
      allow(Errbit::Config).to receive(:smtp_password).and_return('my-password')
      allow(Errbit::Config).to receive(:smtp_domain).and_return('someotherdomain.com')
      load_initializer

      expect(ActionMailer::Base.smtp_settings).to eq({
        address: 'smtp.somedomain.com',
        port: 998,
        authentication: :login,
        user_name: 'my-username',
        password: 'my-password',
        domain: 'someotherdomain.com',
      })
    end
  end
end
