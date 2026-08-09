class PresentTicketPolicy < ApplicationPolicy
  def index?
    user.present? && (user.platform_admin? || user.shop_admin?)
  end

  def show?
    user.platform_admin? || same_shop?
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

  def draw?
    same_shop?
  end

  def send_result_emails?
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
