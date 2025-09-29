# frozen_string_literal: true

module Errbit
  class User < ApplicationRecord
    PER_PAGE = 30

    devise(*Errbit::Config.devise_modules)

    validates :name, presence: true
    validates :github_login, uniqueness: {allow_nil: true}

    def per_page
      super || PER_PAGE
    end

    # def watching?(app)
    #   # apps.all.include?(app)
    # end

    # def password_required?
    #   github_login.present? ? false : super
    # end

    # def github_account?
    #   github_login.present? && github_oauth_token.present?
    # end

    # def can_create_github_issues?
    #   # github_account? && Errbit::Config.github_access_scope.include?("repo")
    # end

    # def github_login=(login)
    #   # login = nil if login.is_a?(String) && login.strip.empty?
    #   # self[:github_login] = login
    # end

    # def google_account?
    #   google_uid.present?
    # end

    # def ensure_authentication_token
    #   # if authentication_token.blank?
    #   #   self.authentication_token = generate_authentication_token
    #   # end
    # end

    # def self.token_authentication_key
    #   # :auth_token
    # end

    # def reset_password(new_password, new_password_confirmation)
    #   # self.password = new_password
    #   # self.password_confirmation = new_password_confirmation
    #   #
    #   # self.class.validators_on(:password).map { |v| v.validate_each(self, :password, password) }
    #   # return false if errors.any?
    #   # save(validate: false)
    # end

    def attributes_for_super_diff
      {
        id: id,
        name: name
      }
    end

    private

    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless Errbit::User.where(authentication_token: token).first
      end
    end
  end
end
