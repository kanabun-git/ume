class ShopProspectPolicy < PlatformAdminPolicy
  def import?
    create?
  end

  def send_outreach_emails?
    create?
  end
end
