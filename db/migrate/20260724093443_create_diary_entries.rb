class CreateDiaryEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :diary_entries do |t|
      t.references :cast, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.integer :status, default: 0, null: false
      t.datetime :published_at

      t.timestamps
    end
  end
end
