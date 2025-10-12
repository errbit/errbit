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
  end

  def create?
  end

  def new?
  end

  def update?
  end

  def edit?
  end

  def destroy?
  end
end
