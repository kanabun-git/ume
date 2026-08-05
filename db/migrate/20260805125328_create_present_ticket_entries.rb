class CreatePresentTicketEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :present_ticket_entries do |t|
      t.references :present_ticket, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :notified_at

      t.timestamps
    end
    add_index :present_ticket_entries, [:present_ticket_id, :member_id], unique: true, name: "index_ticket_entries_on_ticket_and_member"
  end
end
