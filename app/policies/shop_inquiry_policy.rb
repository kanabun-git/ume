class ShopInquiryPolicy < ApplicationPolicy
  # Anyone (including anonymous visitors) can submit a shop registration
  # inquiry; only the platform admin reviews and manages them — shop
  # registration itself stays a platform-admin-only action (see
  # ShopPolicy#create?), this is just the public-facing lead-in to it.
  def create?
    true
  end

  def index?
    user.present? && user.platform_admin?
  end

  def show?
    index?
  end

  def update_status?
    index?
  end

  def archive?
    index?
  end

  def unarchive?
    index?
  end

  class Scope < Scope
    def resolve
      user&.platform_admin? ? scope.all : scope.none
    end
  end
end
