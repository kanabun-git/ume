class CreateMemberRanks < ActiveRecord::Migration[8.1]
  def change
    create_table :member_ranks do |t|
      t.string :name, null: false
      t.integer :min_approved_count, null: false

      t.timestamps
    end
    add_index :member_ranks, :min_approved_count, unique: true
  end
end
