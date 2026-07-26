class ChangeCastPageBlocksToShopScoped < ActiveRecord::Migration[7.2]
  # The girl detail page block composition moved from "one set of blocks per
  # cast" to "one shared set of blocks per shop, applied to every cast in
  # that shop". Existing rows were per-cast (would be duplicate/inconsistent
  # once shared), and this ships pre-launch, so they're cleared and
  # `Shop#seed_default_cast_page_blocks` (called from db/seeds.rb) rebuilds
  # a clean default set per shop instead of trying to reconcile duplicates.
  def up
    execute "DELETE FROM cast_page_blocks"
    remove_index :cast_page_blocks, [:cast_id, :layout_column, :position]
    remove_reference :cast_page_blocks, :cast, foreign_key: true
    add_reference :cast_page_blocks, :shop, null: false, foreign_key: true
    add_index :cast_page_blocks, [:shop_id, :layout_column, :position]
  end

  def down
    execute "DELETE FROM cast_page_blocks"
    remove_index :cast_page_blocks, [:shop_id, :layout_column, :position]
    remove_reference :cast_page_blocks, :shop, foreign_key: true
    add_reference :cast_page_blocks, :cast, null: false, foreign_key: true
    add_index :cast_page_blocks, [:cast_id, :layout_column, :position]
  end
end
