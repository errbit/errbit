# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  FIELDS = [
    :name, :username, :email, :password, :github_login, :per_page, :time_zone,
    :password, :password_confirmation
  ].freeze

  # @param user [User] The user making the request
  # @param record [User] The record being accessed
  def initialize(user, record) # rubocop:disable Style/RedundantInitialize, Lint/UselessMethodDefinition
    super
  end

  def index?
    false
  end

  def show?
    scope.exists?(id: record.id)
  end

  def create?
    user.admin?
  end

  def new?
    create?
  end

  def update?
    scope.exists?(id: record.id)
  end

  def edit?
    scope.exists?(id: record.id)
  end

  def destroy?
    scope.exists?(id: record.id) && user.id != record.id
  end

  def permitted_attributes
    if user.admin? && user.id != record.id
      FIELDS + [:admin]
    else
      FIELDS
    end
  end

  class Scope < ApplicationPolicy::Scope
    attr_reader :user, :scope

    # @param user [User]
    # @param scope [User, Object] The scope of records being accessed
    def initialize(user, scope) # rubocop:disable Style/RedundantInitialize, Lint/UselessMethodDefinition
      super
    end

    def resolve
      if user.admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
end
