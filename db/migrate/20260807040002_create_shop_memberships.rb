class CreateShopMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_memberships do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.text :incident_notes
      t.text :caution_notes

      t.timestamps
    end
    add_index :shop_memberships, [:shop_id, :member_id], unique: true
  end
end
