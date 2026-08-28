class AddPublishedToShops < ActiveRecord::Migration[8.1]
  def up
    add_column :shops, :published, :boolean, null: false, default: false
    # design_updated_at doubles as the "shop admin published a design
    # change" flag surfaced to the platform admin (admin/shops#confirm_design
    # clears it back to nil) -- see Shop#publish!/#confirm_design_reviewed!.
    add_column :shops, :design_updated_at, :datetime

    # Already-approved shops are already live today (Shop.visible used to be
    # just `approved`); flipping the new gate on for them keeps every
    # currently-public shop visible after this deploy.
    execute "UPDATE shops SET published = true WHERE status = 1"
  end

  def down
    remove_column :shops, :design_updated_at
    remove_column :shops, :published
  end
end
