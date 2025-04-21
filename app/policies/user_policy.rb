# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    false
  end

  def show?
    scope.where(id: record.id).exists?
  end

  def create?
    user.admin?
  end

  def new?
    create?
  end

  def update?
    scope.where(id: record.id).exists?
  end

  def edit?
    scope.where(id: record.id).exists?
  end

  def destroy?
    scope.where(id: record.id).exists? && user.id != record.id
  end

  class Scope < ApplicationPolicy::Scope
    attr_reader :user, :scope

    def resolve
      if user.admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
end
