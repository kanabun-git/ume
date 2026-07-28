class AddShopReplyToReviews < ActiveRecord::Migration[7.2]
  def change
    add_column :reviews, :shop_reply, :text
    add_column :reviews, :shop_replied_at, :datetime
  end
end
