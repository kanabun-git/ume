class AddFallbackBannerToPresentTickets < ActiveRecord::Migration[8.1]
  def change
    # Only takes effect when the shop hasn't uploaded its own banner_image
    # (an Active Storage attachment, no column needed) -- lets the shop
    # admin choose between showing nothing or ZERO's shipped banner
    # graphic. See PresentTicket#fallback_banner.
    add_column :present_tickets, :fallback_banner, :integer, null: false, default: 0
  end
end
