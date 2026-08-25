class ShopProspectDistrictPolicy < PlatformAdminPolicy
  def register_area?
    update?
  end
end
