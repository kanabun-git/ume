class CreateCastPageBlocks < ActiveRecord::Migration[7.2]
  def change
    create_table :cast_page_blocks do |t|
      t.references :cast, null: false, foreign_key: true
      t.integer :block_type, null: false
      t.integer :layout_column, default: 0, null: false
      t.integer :position, default: 0, null: false
      t.boolean :visible, default: true, null: false
      t.string :title
      t.string :background_color
      t.decimal :background_opacity, precision: 3, scale: 2, default: 1.0, null: false
      t.jsonb :settings, default: {}, null: false
      t.timestamps
    end
    add_index :cast_page_blocks, [:cast_id, :layout_column, :position]
  end
end
