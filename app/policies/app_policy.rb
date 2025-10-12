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

  class Scope < ApplicationPolicy::Scope
    attr_reader :user, :scope

    # @param user [User]
    # @param scope [App, Object] The scope of records being accessed
    def initialize(user, scope)
      super
    end

    def resolve
      scope.all
    end
  end
end
