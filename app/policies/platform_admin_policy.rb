# Base class for resources that only the platform operator manages
# (areas, genres, plans, subscriptions). Kept separate from ApplicationPolicy
# so intent is explicit at each subclass call site.
class PlatformAdminPolicy < ApplicationPolicy
  def index?
    user.present? && user.platform_admin?
  end

  def show?
    index?
  end

  def create?
    index?
  end

  def update?
    index?
  end

  def destroy?
    index?
  end

  class Scope < Scope
    def resolve
      user&.platform_admin? ? scope.all : scope.none
    end
  end
end
