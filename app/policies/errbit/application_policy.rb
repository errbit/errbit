# frozen_string_literal: true

module Errbit
  class ApplicationPolicy
    attr_reader :user, :record

    # @param user [Errbit::User] The user making the request
    # @param record [Object] The record being accessed
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

    def permitted_attributes
      raise NotImplementedError, "You must define #permitted_attributes in #{self.class}"
    end

    class Scope
      attr_reader :user, :scope

      # @param user [Errbit::User]
      # @param scope [Object] The scope of records being accessed
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
end
