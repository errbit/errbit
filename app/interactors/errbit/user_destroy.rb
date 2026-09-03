# frozen_string_literal: true

module Errbit
  class UserDestroy
    attr_reader :user

    def initialize(user)
      @user = user
    end

    delegate :destroy, to: :user
  end
end
