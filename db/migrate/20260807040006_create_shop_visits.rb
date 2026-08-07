class CreateShopVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_visits do |t|
      t.references :shop_membership, null: false, foreign_key: true
      t.date :visited_on, null: false
      t.integer :points_earned, null: false, default: 0
      t.text :memo

      t.timestamps
    end
  end
end
