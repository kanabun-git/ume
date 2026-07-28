class ReviewPolicy < ApplicationPolicy
  # Reviews are posted by anonymous site visitors, moderated by staff.
  def create?
    true
  end

  def index?
    user.present? && (user.platform_admin? || user.shop_admin?)
  end

  def show?
    index?
  end

  def moderate?
    user.present? && user.platform_admin?
  end

  def destroy?
    moderate?
  end

  # A shop admin can reply to reviews left about their own shop; platform
  # admins can reply to any (e.g. while handling an escalation).
  def reply?
    user.present? && (user.platform_admin? || (user.shop_admin? && record.shop_id == user.shop_id))
  end

  class Scope < Scope
    def resolve
      if user.nil?
        scope.none
      elsif user.platform_admin?
        scope.all
      elsif user.shop_admin?
        scope.where(shop_id: user.shop_id)
      else
        scope.none
      end
    end
  end
end
