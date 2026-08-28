class ShopPolicy < ApplicationPolicy
  def index?
    user.platform_admin?
  end

  def show?
    user.platform_admin? || own_shop?
  end

  def create?
    user.platform_admin?
  end

  def update?
    user.platform_admin? || own_shop?
  end

  # Approving/suspending/changing plan is a platform-admin-only action,
  # separate from editing a shop's own content (name, description, photos).
  def manage_status?
    user.platform_admin?
  end

  # Publishing/unpublishing the shop's page is self-service for the shop
  # admin (see update?) -- clearing the "design changed" notice raised by a
  # publish, on the other hand, is a platform-admin-only acknowledgement.
  def confirm_design?
    user.platform_admin?
  end

  def destroy?
    user.platform_admin?
  end

  class Scope < Scope
    def resolve
      if user.platform_admin?
        scope.all
      elsif user.shop_admin?
        scope.where(id: user.shop_id)
      else
        scope.none
      end
    end
  end

  private

  def own_shop?
    user.shop_admin? && record.id == user.shop_id
  end
end
