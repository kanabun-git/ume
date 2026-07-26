class CastPageBlockPolicy < ApplicationPolicy
  def index?
    user.present? && (user.platform_admin? || same_shop?)
  end

  def show?
    index?
  end

  def create?
    user.present? && (user.platform_admin? || same_shop?)
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  class Scope < Scope
    def resolve
      if user&.platform_admin?
        scope.all
      elsif user&.shop_admin?
        scope.where(shop_id: user.shop_id)
      else
        scope.none
      end
    end
  end

  private

  def same_shop?
    user.shop_admin? && record.shop_id == user.shop_id
  end
end
