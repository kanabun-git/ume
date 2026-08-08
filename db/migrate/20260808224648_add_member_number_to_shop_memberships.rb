class AddMemberNumberToShopMemberships < ActiveRecord::Migration[8.1]
  def up
    add_column :shop_memberships, :member_number, :integer

    execute <<~SQL
      UPDATE shop_memberships
      SET member_number = numbered.row_number
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY shop_id ORDER BY created_at, id) AS row_number
        FROM shop_memberships
      ) AS numbered
      WHERE shop_memberships.id = numbered.id
    SQL

    change_column_null :shop_memberships, :member_number, false
    add_index :shop_memberships, [:shop_id, :member_number], unique: true
  end

  def down
    remove_index :shop_memberships, [:shop_id, :member_number]
    remove_column :shop_memberships, :member_number
  end
end
