class AddViewTrackingToCasts < ActiveRecord::Migration[8.1]
  def change
    add_column :casts, :view_count, :integer, null: false, default: 0

    create_table :cast_daily_views do |t|
      t.references :cast, null: false, foreign_key: true
      t.date :view_date, null: false
      t.integer :views_count, null: false, default: 0

      t.timestamps
    end
    add_index :cast_daily_views, [:cast_id, :view_date], unique: true
  end
end
