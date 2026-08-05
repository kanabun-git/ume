class AddPrBadgeUntilToShops < ActiveRecord::Migration[8.1]
  def change
    add_column :shops, :pr_badge_until, :datetime
  end
end
