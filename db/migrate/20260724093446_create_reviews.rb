class CreateReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :reviews do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :cast, null: true, foreign_key: true
      t.string :reviewer_name, null: false
      t.integer :rating, null: false
      t.text :body, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
