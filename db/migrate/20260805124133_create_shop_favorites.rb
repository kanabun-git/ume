class CreateShopFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_favorites do |t|
      t.references :member, null: false, foreign_key: true
      t.references :shop, null: false, foreign_key: true

      t.timestamps
    end
    add_index :shop_favorites, [:member_id, :shop_id], unique: true
  end
end
