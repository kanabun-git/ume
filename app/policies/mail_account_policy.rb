class MailAccountPolicy < PlatformAdminPolicy
  def test_delivery?
    create?
  end

  def sync?
    create?
  end
end
