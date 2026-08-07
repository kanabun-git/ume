class CreateShopPointTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_point_transactions do |t|
      t.references :shop_membership, null: false, foreign_key: true
      t.integer :amount, null: false
      t.string :reason, null: false

      t.timestamps
    end
  end
end
