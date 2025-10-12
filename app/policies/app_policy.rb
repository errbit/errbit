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
    admin?
  end

  def new?
    admin?
  end

  def update?
    admin?
  end

  def edit?
    admin?
  end

  def destroy?
    admin?
  end
end
