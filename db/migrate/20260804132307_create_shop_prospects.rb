class CreateShopProspects < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_prospects do |t|
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.string :listing_site_name
      t.string :listing_url
      t.integer :status, null: false, default: 0
      t.text :memo

      t.timestamps
    end
  end
end
