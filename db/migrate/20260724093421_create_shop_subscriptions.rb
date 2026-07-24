class CreateShopSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :shop_subscriptions do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.date :started_on, null: false
      t.date :ended_on
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
