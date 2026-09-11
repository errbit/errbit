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
      valid_email_domain?(email, Errbit::Config.google_authorized_domains)
    end

    # @param email [String]
    def valid_oidc_domain?(email)
      valid_email_domain?(email, Errbit::Config.oidc_authorized_domains)
    end

    # @param email [String]
    # @param domains [String, nil] comma separated list, blank means "any"
    def valid_email_domain?(email, domains)
      return true if domains.blank?

      match_data = /.+@(?<domain>.+)$/.match(email.to_s.downcase)
      return false if match_data.nil?

      domains.split(",").map { |domain| domain.strip.downcase }.include?(match_data[:domain])
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

    # Provisions the account of an OpenID Connect identity nothing is linked
    # to yet.
    #
    # @param auth [OmniAuth::AuthHash]
    # @return [User, nil] the account, saved or carrying the errors that kept
    #   it from being saved, or nil when an account with that email address
    #   exists but may not be claimed on the provider's word alone
    def create_from_oidc(auth)
      email = auth.dig(:info, :email).to_s.downcase
      name = auth.dig(:info, :name).presence || auth.dig(:info, :nickname).presence || email
      uid = auth[:uid]

      user = User.where(email: email).first

      if user.nil?
        return User.create(name: name,
          email: email,
          oidc_uid: uid,
          password: Devise.friendly_token[0, 20])
      end

      # An account that predates the OpenID Connect setup is claimed rather
      # than duplicated, but only when nothing about it argues against it:
      # the provider has to say it verified the address, the account must
      # not already answer to an identity, and it must not be an admin
      # account. Anything else and an address somebody set on their own
      # provider account would be a way into an Errbit account - along with
      # its admin flag and its stored GitHub token. Such an account is
      # linked from the inside instead, by signing in to it.
      return nil unless auth.dig(:info, :email_verified) == true
      return nil if user.linked_identity? || user.admin?

      user.update(oidc_uid: uid)
      user
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

  def oidc_account?
    oidc_uid.present?
  end

  # Whether some external identity already signs this account in.
  def linked_identity?
    oidc_uid.present? || github_login.present? || google_uid.present?
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
