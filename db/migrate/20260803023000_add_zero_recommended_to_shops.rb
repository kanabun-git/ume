class AddZeroRecommendedToShops < ActiveRecord::Migration[8.1]
  def change
    add_column :shops, :zero_recommended, :boolean, default: false, null: false
  end
end
