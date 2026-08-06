class CreateCoupons < ActiveRecord::Migration[8.1]
  def change
    create_table :coupons do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :title, null: false
      t.string :course_name, null: false
      t.integer :regular_price, null: false
      t.integer :discounted_price, null: false
      t.date :valid_from, null: false
      t.date :valid_until
      t.text :conditions
      t.boolean :net_reservation_only, null: false, default: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
