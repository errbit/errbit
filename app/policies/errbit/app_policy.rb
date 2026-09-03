# frozen_string_literal: true

module Errbit
  class AppPolicy < ApplicationPolicy
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
      def resolve
        scope.all
      end
    end
  end
end
