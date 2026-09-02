class ChangeVisitedOnToVisitedAtOnShopVisits < ActiveRecord::Migration[8.1]
  def up
    rename_column :shop_visits, :visited_on, :visited_at
    change_column :shop_visits, :visited_at, :datetime, using: "visited_at::timestamp"
  end

  def down
    change_column :shop_visits, :visited_at, :date
    rename_column :shop_visits, :visited_at, :visited_on
  end
end
