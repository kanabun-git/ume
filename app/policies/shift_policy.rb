class ShiftPolicy < ApplicationPolicy
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

  def destroy?
    user.present? && (user.platform_admin? || create?)
  end

  class Scope < Scope
    def resolve
      if user.nil?
        scope.all
      elsif user.platform_admin?
        scope.all
      elsif user.shop_admin?
        scope.joins(:cast).where(casts: { shop_id: user.shop_id })
      elsif user.cast?
        scope.where(cast_id: user.cast_profile&.id)
      else
        scope.none
      end
    end
  end
end
