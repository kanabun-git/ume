class AddPickUpToCasts < ActiveRecord::Migration[7.2]
  def change
    add_column :casts, :pick_up, :boolean, default: false, null: false
  end
end
