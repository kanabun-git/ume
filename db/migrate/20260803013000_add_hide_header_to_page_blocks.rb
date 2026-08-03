class AddHideHeaderToPageBlocks < ActiveRecord::Migration[8.1]
  def change
    add_column :shop_page_blocks, :hide_header, :boolean, default: false, null: false
    add_column :cast_page_blocks, :hide_header, :boolean, default: false, null: false
  end
end
