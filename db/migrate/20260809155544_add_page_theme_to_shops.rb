class AddPageThemeToShops < ActiveRecord::Migration[8.1]
  def change
    add_column :shops, :page_background_color, :string
    add_column :shops, :page_text_color, :string
    add_column :shops, :page_accent_color, :string
  end
end
