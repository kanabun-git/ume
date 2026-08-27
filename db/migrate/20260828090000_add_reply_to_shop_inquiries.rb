class AddReplyToShopInquiries < ActiveRecord::Migration[8.1]
  def change
    add_column :shop_inquiries, :reply_body, :text
    add_column :shop_inquiries, :replied_at, :datetime
  end
end
