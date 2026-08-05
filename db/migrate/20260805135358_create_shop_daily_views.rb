class CreateShopDailyViews < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_daily_views do |t|
      t.references :shop, null: false, foreign_key: true
      t.date :view_date, null: false
      t.integer :views_count, null: false, default: 0

      t.timestamps
    end
    add_index :shop_daily_views, [:shop_id, :view_date], unique: true
  end
end
