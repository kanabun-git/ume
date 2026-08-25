class AddOutreachTrackingToShopProspects < ActiveRecord::Migration[8.1]
  def up
    add_column :shop_prospects, :outreach_token, :string
    add_column :shop_prospects, :outreach_email_sent_at, :datetime
    add_column :shop_prospects, :outreach_link_clicked_at, :datetime

    # Backfill existing rows (created by hand or CSV import before this
    # feature existed) so every prospect always has a token ready --
    # ShopProspect#before_create only covers rows created from here on.
    ShopProspect.reset_column_information
    ShopProspect.find_each do |prospect|
      prospect.update_column(:outreach_token, SecureRandom.hex(16))
    end

    change_column_null :shop_prospects, :outreach_token, false
    add_index :shop_prospects, :outreach_token, unique: true
  end

  def down
    remove_index :shop_prospects, :outreach_token
    remove_column :shop_prospects, :outreach_link_clicked_at
    remove_column :shop_prospects, :outreach_email_sent_at
    remove_column :shop_prospects, :outreach_token
  end
end
