class ShopMembershipPolicy < ApplicationPolicy
  def index?
    user.present? && user.shop_admin?
  end

  def show?
    same_shop?
  end

  def update?
    same_shop?
  end

  class Scope < Scope
    def resolve
      user&.shop_admin? ? scope.where(shop_id: user.shop_id) : scope.none
    end
  end

  private

  def same_shop?
    user.present? && user.shop_admin? && record.shop_id == user.shop_id
  end
end
