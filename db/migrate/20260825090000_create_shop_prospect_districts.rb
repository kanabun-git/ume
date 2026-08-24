class CreateShopProspectDistricts < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_prospect_districts do |t|
      t.string :name, null: false
      # Every district registered so far comes from Tokyo-area listing
      # exports; admins can correct this per district once other
      # prefectures start showing up (see Admin::ShopProspectDistrictsController).
      t.string :prefecture, null: false, default: "東京"

      t.timestamps
    end
    add_index :shop_prospect_districts, :name, unique: true

    add_reference :shop_prospects, :shop_prospect_district, foreign_key: true, index: true
  end
end
