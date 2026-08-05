class CreatePresentTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :present_tickets do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :capacity, null: false
      t.datetime :deadline_at, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
