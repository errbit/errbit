# frozen_string_literal: true

class AppPolicy < ApplicationPolicy
  # @param user [User] The user making the request
  # @param record [App] The record being accessed
  def initialize(user, record)
    super
  end

  def index?
    false
  end
end
