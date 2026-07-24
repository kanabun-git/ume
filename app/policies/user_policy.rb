class UserPolicy < ApplicationPolicy
  def index?
    user.platform_admin? || user.shop_admin?
  end

  def show?
    user.platform_admin? || same_shop_cast?
  end

  def create?
    user.platform_admin? || (user.shop_admin? && record.cast? )
  end

  def update?
    user.platform_admin? || same_shop_cast?
  end

  def destroy?
    user.platform_admin? || same_shop_cast?
  end

  class Scope < Scope
    def resolve
      if user.platform_admin?
        scope.all
      elsif user.shop_admin?
        scope.where(shop_id: user.shop_id, role: :cast)
      else
        scope.none
      end
    end
  end

  private

  def same_shop_cast?
    user.shop_admin? && record.cast? && record.shop_id == user.shop_id
  end
end
