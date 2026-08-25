class AddArchivedAtToShopInquiries < ActiveRecord::Migration[8.1]
  def change
    add_column :shop_inquiries, :archived_at, :datetime
  end
end
