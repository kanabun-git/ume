class AddRegionToAreas < ActiveRecord::Migration[7.2]
  def change
    add_column :areas, :region, :string
  end
end
