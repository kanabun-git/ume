class CreatePlans < ActiveRecord::Migration[7.2]
  def change
    create_table :plans do |t|
      t.string  :name, null: false
      t.integer :monthly_fee, default: 0, null: false
      t.integer :priority_weight, default: 1, null: false
      t.integer :position, default: 0, null: false

      t.timestamps
    end
  end
end
