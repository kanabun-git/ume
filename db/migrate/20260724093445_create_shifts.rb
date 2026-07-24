class CreateShifts < ActiveRecord::Migration[7.2]
  def change
    create_table :shifts do |t|
      t.references :cast, null: false, foreign_key: true
      t.date :work_date, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.string :note
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
