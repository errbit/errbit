# frozen_string_literal: true

class User
  PER_PAGE = 30

  include Mongoid::Document
  include Mongoid::Timestamps

  devise(*Errbit::Config.devise_modules)

  field :email
  field :github_login
  field :github_oauth_token
  field :google_uid
  field :oidc_issuer
  field :oidc_uid
  field :name
  field :admin, type: Boolean, default: false
  field :per_page, type: Integer, default: PER_PAGE
  field :time_zone, default: "UTC"

  ## Devise field
  ### Database Authenticatable
  field :encrypted_password, type: String

  ### Recoverable
  field :reset_password_token, type: String
  field :reset_password_sent_at, type: Time

  ### Rememberable
  field :remember_created_at, type: Time

  ### Trackable
  field :sign_in_count, type: Integer
  field :current_sign_in_at, type: Time
  field :last_sign_in_at, type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip, type: String

  ### Token_authenticatable
  field :authentication_token, type: String

  index authentication_token: 1
  index({oidc_issuer: 1, oidc_uid: 1}, unique: true, sparse: true)

  before_save :ensure_authentication_token

  validates :name, presence: true
  validates :github_login, uniqueness: {allow_nil: true}

  if Errbit::Config.user_has_username
    field :username
    validates :username, presence: true
  end

  class << self
    # @param email [String]
    def valid_google_domain?(email)
      return true if Errbit::Config.google_authorized_domains.blank?

      match_data = /.+@(?<domain>.+)$/.match(email)
      return false if match_data.nil?

      Errbit::Config.google_authorized_domains.split(",").include?(match_data[:domain])
    end

    # @param access_token [String]
    def create_from_google_oauth2(access_token) # rubocop:disable Naming/VariableNumber
      email = access_token.dig(:info, :email)
      name = access_token.dig(:info, :name)
      uid = access_token[:uid]

      user = User.where(email: email).first

      user || User.create(name: name,
        email: email,
        google_uid: uid,
        password: Devise.friendly_token[0, 20])
    end

    def find_or_create_from_openid_connect(auth, auto_provision: false)
      issuer = Errbit::Config.oidc_issuer
      uid = auth[:uid].to_s
      return if issuer.blank? || uid.blank?

      user = where(oidc_issuer: issuer, oidc_uid: uid).first
      return user if user

      email = auth.dig(:info, :email).to_s.strip.downcase
      return unless email.present? && oidc_email_verified?(auth)

      user = where(email: email, oidc_issuer: nil, oidc_uid: nil).find_one_and_update(
        {"$set" => {oidc_issuer: issuer, oidc_uid: uid}},
        return_document: :after
      )
      return user if user

      user = where(oidc_issuer: issuer, oidc_uid: uid).first
      return user if user

      user = where(email: email).first
      return if user && (user.oidc_uid.present? || user.oidc_issuer.present?)
      return unless auto_provision

      return if oidc_authorized_domains.present? && oidc_authorized_domains.exclude?(email.split("@").last)

      begin
        create(
          name: auth.dig(:info, :name).presence || email,
          email: email,
          oidc_issuer: issuer,
          oidc_uid: uid,
          password: Devise.friendly_token[0, 20]
        )
      rescue Mongo::Error::OperationFailure => error
        raise unless error.code == 11_000

        where(oidc_issuer: issuer, oidc_uid: uid).first
      end
    end

    def oidc_email_verified?(auth)
      verified = auth.dig(:info, :email_verified)
      verified = auth.dig(:extra, :raw_info, :email_verified) if verified.nil?
      verified == true || verified.to_s.casecmp("true").zero?
    end

    def oidc_authorized_domains
      Errbit::Config.oidc_authorized_domains.to_s.split(",").map { |domain| domain.strip.downcase }.reject(&:blank?)
    end
  end

  def per_page
    super || PER_PAGE
  end

  def watching?(app)
    apps.all.include?(app)
  end

  def password_required?
    github_login.present? ? false : super
  end

  def github_account?
    github_login.present? && github_oauth_token.present?
  end

  def can_create_github_issues?
    github_account? && Errbit::Config.github_access_scope.include?("repo")
  end

  def github_login=(login)
    login = nil if login.is_a?(String) && login.strip.empty?
    self[:github_login] = login
  end

  def google_account?
    google_uid.present?
  end

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  def self.token_authentication_key
    :auth_token
  end

  def reset_password(new_password, new_password_confirmation)
    self.password = new_password
    self.password_confirmation = new_password_confirmation

    self.class.validators_on(:password).map { |v| v.validate_each(self, :password, password) }
    return false if errors.any?

    save(validate: false)
  end

  def attributes_for_super_diff
    {
      id: id.to_s,
      name: name
    }
  end

  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end
end
