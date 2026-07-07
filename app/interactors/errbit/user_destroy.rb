# frozen_string_literal: true

module Errbit
  class UserDestroy
    attr_reader :user

    # @param user [Errbit::User] User to destroy
    def initialize(user)
      @user = user
    end

    # Cleanup is handled by Errbit::User's `has_many :watchers, dependent: :destroy`
    # and `has_many :comments, dependent: :destroy` associations.
    def destroy
      user.destroy
    end
  end
end
