class CreateShopMemberBenefitGrants < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_member_benefit_grants do |t|
      t.references :shop_membership, null: false, foreign_key: true
      t.references :shop_member_benefit, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :used_at

      t.timestamps
    end
  end
end
