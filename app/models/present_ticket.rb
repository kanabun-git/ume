class PresentTicket < ApplicationRecord
  belongs_to :shop
  has_many :present_ticket_entries, dependent: :destroy
  has_many :members, through: :present_ticket_entries

  enum :status, { accepting: 0, drawn: 1, closed: 2 }, default: :accepting

  validates :name, presence: true
  validates :capacity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :deadline_at, presence: true

  default_scope { order(created_at: :desc) }

  scope :open_for_entry, -> { accepting.where("deadline_at > ?", Time.current) }

  # Randomly picks `capacity` winners among the still-pending entries and
  # marks the rest lost. Only meaningful once, from `accepting` — calling
  # it again after the ticket is already `drawn` would re-shuffle winners
  # and email history that's already been sent, so it's a no-op then.
  def draw!
    return false unless accepting?

    transaction do
      pending_entries = present_ticket_entries.where(status: :pending).to_a
      winners = pending_entries.sample([capacity, pending_entries.size].min)
      winner_ids = winners.map(&:id)

      present_ticket_entries.where(id: winner_ids).update_all(status: PresentTicketEntry.statuses[:won])
      present_ticket_entries.where(status: :pending).update_all(status: PresentTicketEntry.statuses[:lost])
      update!(status: :drawn)
    end

    true
  end
end
