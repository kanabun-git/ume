class CreateCouponUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :coupon_usages do |t|
      t.references :coupon, null: false, foreign_key: true
      t.integer :usage_type, null: false, default: 0

      t.timestamps
    end
  end
end
