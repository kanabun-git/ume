class PresentTicketPolicy < ApplicationPolicy
  def index?
    user.present? && (user.platform_admin? || user.shop_admin?)
  end

  def show?
    user.platform_admin? || same_shop?
  end

  def create?
    user.present? && (user.platform_admin? || user.shop_admin?)
  end

  def update?
    user.platform_admin? || same_shop?
  end

  def destroy?
    user.platform_admin? || same_shop?
  end

  def draw?
    user.platform_admin? || same_shop?
  end

  def send_result_emails?
    user.platform_admin? || same_shop?
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
    user.present? && user.shop_admin? && record.shop_id == user.shop_id
  end
end
