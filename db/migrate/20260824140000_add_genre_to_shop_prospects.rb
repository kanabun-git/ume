class AddGenreToShopProspects < ActiveRecord::Migration[8.1]
  def change
    add_column :shop_prospects, :genre, :string
  end
end
