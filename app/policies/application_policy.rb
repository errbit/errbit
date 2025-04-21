# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  # @param user [User] The user making the request
  # @param record [Mongoid::Document] The record being accessed
  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" if user.blank?

    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    false
  end

  def update?
    false
  end

  def edit?
    false
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  class Scope
    attr_reader :user, :scope

    # @param user [User]
    # @param scope [Mongoid::Criteria] The scope of records being accessed
    def initialize(user, scope)
      raise Pundit::NotAuthorizedError, "must be logged in" if user.blank?

      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end
  end
end
