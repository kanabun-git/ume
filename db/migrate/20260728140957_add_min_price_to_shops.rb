class AddMinPriceToShops < ActiveRecord::Migration[7.2]
  def change
    add_column :shops, :min_price, :integer
  end
end
