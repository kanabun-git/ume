class CreateShopPageBlocks < ActiveRecord::Migration[7.2]
  def change
    create_table :shop_page_blocks do |t|
      t.references :shop, null: false, foreign_key: true
      t.integer :block_type, null: false
      t.integer :position, default: 0, null: false
      t.boolean :visible, default: true, null: false
      t.string :title
      t.string :background_color
      t.decimal :background_opacity, precision: 3, scale: 2, default: 1.0, null: false
      t.jsonb :settings, default: {}, null: false

      t.timestamps
    end

    add_index :shop_page_blocks, [:shop_id, :position]
  end
end
