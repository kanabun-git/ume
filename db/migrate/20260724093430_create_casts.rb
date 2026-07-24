class CreateCasts < ActiveRecord::Migration[7.2]
  def change
    create_table :casts do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true, index: { unique: true }
      t.string :name, null: false
      t.string :alias_name
      t.integer :age
      t.integer :height
      t.integer :bust
      t.integer :waist
      t.integer :hip
      t.string :cup
      t.string :catch_copy
      t.text :description
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
