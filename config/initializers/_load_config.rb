Dotenv.load('.env.default')

module Errbit
  class Configurator
    MAPPING = {
      :host     => [:string, ENV['ERRBIT_HOST']],
      :protocol => [:string, ENV['ERRBIT_PROTOCOL']],
      :port     => [:string, ENV['ERRBIT_PORT']],
      :enforce_ssl => [:boolean, ENV['ERRBIT_ENFORCE_SSL']],
      :confirm_resolve_err => [:boolean, ENV['CONFIRM_RESOLVE_ERR']],
      :confirm_err_actions => [:boolean, ENV['ERRBIT_CONFIRM_ERR_ACTIONS']],
      :user_has_username => [:boolean, ENV['ERRBIT_USER_HAS_USERNAME']],
      :use_gravatar => [:boolean, ENV['ERRBIT_USE_GRAVATAR']],
      :gravatar_default => [:string, ENV['ERRBIT_GRAVATAR_DEFAULT']],
      :display_internal_errors => [:boolean, ENV['DISPLAY_INTERNAL_ERRORS']],
      :allow_comments_with_issue_tracker => [:boolean, ENV['ALLOW_COMMENTS_WITH_ISSUE_TRACKER']],
      :serve_static_assets => [:boolean, ENV['SERVE_STATIC_ASSETS']],
      :secret_key_base => [:string, ENV['SECRET_KEY_BASE']],

      :mongo_url => [:string, ENV['MONGOLAB_URI'], ENV['MONGOHQ_URL'], ENV['MONGODB_URL'], ENV['MONGO_URL']],

      :mongoid_host => [:string, ENV['MONGOID_HOST']],
      :mongoid_port => [:string, ENV['MONGOID_PORT']],
      :mongoid_username => [:string, ENV['MONGOID_USERNAME']],
      :mongoid_password => [:string, ENV['MONGOID_PASSWORD']],
      :mongoid_database => [:string, ENV['MONGOID_DATABASE']],

      :email_from => [:string, ENV['ERRBIT_EMAIL_FROM']],
      :email_at_notices => [:array, ENV['ERRBIT_EMAIL_AT_NOTICES']],
      :per_app_email_at_notices => [:boolean, ENV['PER_APP_EMAIL_AT_NOTICES']],

      :notify_at_notices => [:array, ENV['NOTIFY_AT_NOTICES']],
      :per_app_notify_at_notices => [:boolean, ENV['PER_APP_NOTIFY_AT_NOTICES']],

      # github
      :github_url => [:string, ENV['GITHUB_URL']],
      :github_authentication => [:boolean, ENV['GITHUB_AUTHENTICATION']],
      :github_client_id => [:string, ENV['GITHUB_AUTHENTICATION']],
      :github_secret => [:string, ENV['GITHUB_SECRET']],
      :github_org_id => [:string, ENV['GITHUB_ORG_ID']],
      :github_access_scope => [:array, ENV['GITHUB_ACCESS_SCOPE']],

      :email_delivery_method => [:symbol, ENV['EMAIL_DELIVERY_METHOD']],

      # smtp settings
      :smtp_address        => [:string, ENV['SMTP_SERVER']],
      :smtp_port           => [:integer, ENV['SMTP_PORT']],
      :smtp_authentication => [:symbol, ENV['SMTP_AUTHENTICATION']],
      :smtp_user_name      => [:string, ENV['SMTP_USERNAME'], ENV['SENDGRID_USERNAME']],
      :smtp_password       => [:string, ENV['SMTP_PASSWORD'], ENV['SENDGRID_PASSWORD']],
      :smtp_domain         => [:string, ENV['SMTP_DOMAIN'], ENV['SENDGRID_DOMAIN']],

      # sendmail settings
      :sendmail_location   => [:string, ENV['SENDMAIL_LOCATION']],
      :sendmail_arguments  => [:string, ENV['SENDMAIL_ARGUMENTS']],

      :devise_modules => [:array, ENV['DEVISE_MODULES']],
    }

    @resolved_data = {}

    def self.string(v)
      return nil if v == nil

      v.to_s
    end

    def self.array(v)
      return [] if v == nil

      v.split(',').map(&:strip)
    end

    def self.boolean(v)
      return false if v == nil
      return false if v == 'false'
      return false if v == 0
      return true  if v == 'true'
      return true  if v == 1
      return true  if v == true
      return false
    end

    def self.integer(v)
      return nil if v == nil
      v.to_i
    end

    def self.symbol(v)
      return nil if v == nil
      v.to_sym
    end

    MAPPING.each do |key, _|
      values    = MAPPING[key].dup
      type      = values.shift

      @resolved_data[key] = send(type, values.find { |value| value != nil })

      define_method(key.to_s + '=') do |value|
        self.class.set(key, value)
      end

      define_method(key) do
        self.class.get(key)
      end
    end

    def self.get(key)
      @resolved_data[key]
    end

    def self.set(key, value)
      @resolved_data[key] = value
    end

    def smtp_domain
      self.class.get(:smtp_domain) ||
      (email_from && email_from.split('@').last) ||
      nil
    end

    def github_url
      self.class.get(:github_url).gsub(/\/*\z/, '')
    end

    def devise_modules
      (self.class.get(:devise_modules) || []).map(&:to_sym)
    end

    def email_at_notices
      self.class.get(:email_at_notices).map(&:to_i)
    end

    def notify_at_notices
      self.class.get(:notify_at_notices).map(&:to_i)
    end

    def mongoid_settings
      @parsed_mongo_url ||= if mongo_url
        URI.parse(self.class.get(:mongo_url))
      else
        OpenStruct.new(
          host:     self.class.get(:mongoid_host),
          port:     self.class.get(:mongoid_port),
          user:     self.class.get(:mongoid_username),
          password: self.class.get(:mongoid_password)
        )
      end
    end

    def mongoid_host
      sprintf("%s:%s", mongoid_settings.host, mongoid_settings.port)
    end

    def mongoid_user
      mongoid_settings.user
    end

    def mongoid_password
      mongoid_settings.password
    end

    def mongoid_database
      if mongoid_settings.path
        mongoid_settings.path.gsub(/^\//, '')
      elsif self.class.get(:mongoid_database)
        self.class.get(:mongoid_database)
      else
        sprintf('%s_%s', 'errbit', Rails.env)
      end
    end
  end
end

Errbit::Config = Errbit::Configurator.new

# Set SMTP settings if given.
if Errbit::Config.email_delivery_method == :smtp
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    :address        => Errbit::Config.smtp_address,
    :port           => Errbit::Config.smtp_port,
    :authentication => Errbit::Config.smtp_authentication,
    :user_name      => Errbit::Config.smtp_user_name,
    :password       => Errbit::Config.smtp_password,
    :domain         => Errbit::Config.smtp_domain,
  }
end

if Errbit::Config.email_delivery_method == :sendmail
  ActionMailer::Base.delivery_method = :sendmail

  sendmail_settings = {}
  sendmail_settings[:location] = Errbit::Config.sendmail_location if Errbit::Config.sendmail_location
  sendmail_settings[:arguments] = Errbit::Config.sendmail_arguments if Errbit::Config.sendmail_arguments

  ActionMailer::Base.sendmail_settings = sendmail_settings
end

# Set config specific values
(ActionMailer::Base.default_url_options ||= {}).tap do |default|
  options_from_config = {
    host: Errbit::Config.host,
    port: Errbit::Config.port,
    protocol: Errbit::Config.protocol
  }.select { |k, v| v }

  default.reverse_merge!(options_from_config)
end

Rails.application.config.consider_all_requests_local = Errbit::Config.display_internal_errors
Rails.application.config.serve_static_assets = Errbit::Config.serve_static_assets
Rails.application.config.secret_key_base = Errbit::Config.secret_key_base
