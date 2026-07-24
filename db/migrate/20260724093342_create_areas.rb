class CreateAreas < ActiveRecord::Migration[7.2]
  def change
    create_table :areas do |t|
      t.string :name, null: false
      t.string :name_kana
      t.string :slug, null: false
      t.references :parent, null: true, foreign_key: { to_table: :areas }
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :areas, :slug, unique: true
  end
end
