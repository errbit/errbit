# frozen_string_literal: true

module Errbit
  class UserDestroy
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def destroy
      user.destroy
    end
  end
end
