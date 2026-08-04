class ShopProspectPolicy < PlatformAdminPolicy
  def import?
    create?
  end
end
