class ShopMemberBenefitPolicy < ApplicationPolicy
  def index?
    user.present? && user.shop_admin?
  end

  def create?
    user.present? && user.shop_admin?
  end

  def update?
    same_shop?
  end

  def destroy?
    same_shop?
  end

  private

  def same_shop?
    user.present? && user.shop_admin? && record.shop_member_rank.shop_id == user.shop_id
  end
end
