class CreateShops < ActiveRecord::Migration[7.2]
  def change
    create_table :shops do |t|
      t.string :name, null: false
      t.references :area, null: false, foreign_key: true
      t.references :genre, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.string :catch_copy
      t.text :description
      t.string :address
      t.string :phone
      t.string :business_hours
      t.integer :status, default: 0, null: false
      t.integer :view_count, default: 0, null: false

      t.timestamps
    end

    add_foreign_key :users, :shops
  end
end
