# frozen_string_literal: true

module Errbit
  class UserPolicy < ApplicationPolicy
    FIELDS = [
      :name, :username, :email, :password, :github_login, :per_page, :time_zone,
      :password, :password_confirmation
    ].freeze

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
      def resolve
        if user.admin?
          scope.all
        else
          scope.where(id: user.id)
        end
      end
    end
  end
end
