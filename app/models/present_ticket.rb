class PresentTicket < ApplicationRecord
  include AttachedImageValidatable

  belongs_to :shop
  has_many :present_ticket_entries, dependent: :destroy
  has_many :members, through: :present_ticket_entries
  has_one_attached :banner_image

  enum :status, { accepting: 0, drawn: 1, closed: 2 }, default: :accepting
  # Only takes effect when banner_image isn't attached -- lets the shop
  # admin choose between showing nothing or ZERO's shipped banner graphic,
  # rather than the campaign card having no visual pull at all. See
  # ApplicationHelper#present_ticket_banner_tag.
  enum :fallback_banner, { no_banner: 0, default_banner: 1 }, default: :no_banner, prefix: true

  FALLBACK_BANNER_LABELS = {
    "no_banner" => "表示しない",
    "default_banner" => "ZEROの標準画像を表示する"
  }.freeze

  RECOMMENDED_BANNER_SIZE = "1200×300px前後(横長)".freeze
  DEFAULT_BANNER_IMAGE = "present_ticket_banner_default.svg"

  validates :name, presence: true
  validates :capacity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :deadline_at, presence: true
  validate :validate_banner_image

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

  private

  def validate_banner_image
    return unless banner_image.attached?

    blob = banner_image.blob
    if blob.byte_size > AttachedImageValidatable::MAX_FILE_SIZE
      errors.add(:banner_image, "は5MBまでのファイルを指定してください")
    end
    unless AttachedImageValidatable::ALLOWED_CONTENT_TYPES.include?(blob.content_type)
      errors.add(:banner_image, "はJPEG・PNG・WEBP形式の画像を指定してください")
    end
  end
end
