class CreateShopMemberRanks < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_member_ranks do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :min_visit_count, null: false

      t.timestamps
    end
    add_index :shop_member_ranks, [:shop_id, :min_visit_count], unique: true
  end
end
