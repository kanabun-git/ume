class AddShopProspectToShopInquiries < ActiveRecord::Migration[8.1]
  def change
    add_reference :shop_inquiries, :shop_prospect, foreign_key: true, index: true
  end
end
