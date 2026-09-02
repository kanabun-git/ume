class AddCastAndDesignationToShopVisits < ActiveRecord::Migration[8.1]
  def change
    add_reference :shop_visits, :cast, null: true, foreign_key: true
    add_column :shop_visits, :designation, :integer
    add_column :shop_visits, :duration_minutes, :integer
    add_column :shop_visits, :checked_in_by_qr, :boolean, default: false, null: false
  end
end
