class PresentTicketEntry < ApplicationRecord
  belongs_to :present_ticket
  belongs_to :member

  enum :status, { pending: 0, won: 1, lost: 2 }, default: :pending

  validates :member_id, uniqueness: { scope: :present_ticket_id }

  def notified?
    notified_at.present?
  end
end
