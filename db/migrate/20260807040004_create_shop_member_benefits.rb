class CreateShopMemberBenefits < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_member_benefits do |t|
      t.references :shop_member_rank, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :benefit_type, null: false, default: 0

      t.timestamps
    end
  end
end
