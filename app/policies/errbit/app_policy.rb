# frozen_string_literal: true

module Errbit
  class AppPolicy < ApplicationPolicy
    # @param user [Errbit::User] The user making the request
    # @param record [Errbit::App] The record being accessed
    def initialize(user, record) # rubocop:disable Style/RedundantInitialize, Lint/UselessMethodDefinition
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

      # @param user [Errbit::User]
      # @param scope [Errbit::App, Object] The scope of records being accessed
      def initialize(user, scope) # rubocop:disable Style/RedundantInitialize, Lint/UselessMethodDefinition
        super
      end

      def resolve
        scope.all
      end
    end
  end
end
