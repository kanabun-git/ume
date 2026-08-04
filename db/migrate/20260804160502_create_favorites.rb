class CreateFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :favorites do |t|
      t.references :member, null: false, foreign_key: true
      t.references :cast, null: false, foreign_key: true

      t.timestamps
    end
    add_index :favorites, [:member_id, :cast_id], unique: true
  end
end
