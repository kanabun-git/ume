class CastPolicy < ApplicationPolicy
  def index?
    user.platform_admin? || user.shop_admin?
  end

  def show?
    user.platform_admin? || same_shop? || own_record?
  end

  def create?
    user.platform_admin? || user.shop_admin?
  end

  def update?
    user.platform_admin? || same_shop? || own_record?
  end

  def destroy?
    user.platform_admin? || same_shop?
  end

  # Only the cast themself edits their public-facing profile fields
  # (photos, catch copy, sizes); shop admins manage roster membership/status.
  def update_profile?
    user.platform_admin? || own_record?
  end

  class Scope < Scope
    def resolve
      if user.platform_admin?
        scope.all
      elsif user.shop_admin?
        scope.where(shop_id: user.shop_id)
      elsif user.cast?
        scope.where(user_id: user.id)
      else
        scope.none
      end
    end
  end

  private

  def same_shop?
    user.shop_admin? && record.shop_id == user.shop_id
  end

  def own_record?
    user.cast? && record.user_id == user.id
  end
end
