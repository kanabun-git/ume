class AddCastAndCouponNumberToCoupons < ActiveRecord::Migration[8.1]
  def change
    add_column :coupons, :coupon_number, :string
    add_reference :coupons, :cast, null: true, foreign_key: true
  end
end
