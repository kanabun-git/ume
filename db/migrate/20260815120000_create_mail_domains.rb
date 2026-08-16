class CreateMailDomains < ActiveRecord::Migration[8.1]
  def change
    create_table :mail_domains do |t|
      t.string :name, null: false
      t.string :domain, null: false
      t.text :note

      t.timestamps
    end
    add_index :mail_domains, :domain, unique: true
  end
end
