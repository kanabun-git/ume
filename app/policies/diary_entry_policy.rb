class DiaryEntryPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.present? && user.cast? && record.cast_id == user.cast_profile&.id
  end

  def update?
    create?
  end

  # Shop admins cannot edit a cast's diary content, but platform admins
  # can remove entries as part of content moderation.
  def destroy?
    user.present? && (user.platform_admin? || create?)
  end

  # Hiding an individual diary photo (content moderation) is
  # platform-admin-only, distinct from destroying the whole entry above.
  def manage_visibility?
    user.present? && user.platform_admin?
  end

  class Scope < Scope
    def resolve
      if user.nil?
        scope.visible
      elsif user.platform_admin?
        scope.all
      elsif user.shop_admin?
        scope.joins(:cast).where(casts: { shop_id: user.shop_id })
      elsif user.cast?
        scope.where(cast_id: user.cast_profile&.id)
      else
        scope.visible
      end
    end
  end
end
