class CreatePageDailyViews < ActiveRecord::Migration[8.1]
  def change
    create_table :page_daily_views do |t|
      # "index" (TOP/年齢確認ページ), "kanto", "chubu" -- see PageDailyView::PAGE_KEYS.
      t.string :page_key, null: false
      t.date :view_date, null: false
      t.integer :views_count, default: 0, null: false

      t.timestamps
    end
    add_index :page_daily_views, [:page_key, :view_date], unique: true
  end
end
