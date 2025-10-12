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

  def show?
    true
  end

  def create?
    user.admin?
  end

  def new?
    user.admin?
  end

  def update?
    user.admin?
  end

  def edit?
    user.admin?
  end

  def destroy?
    user.admin?
  end
end
