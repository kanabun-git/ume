class CreateMailAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :mail_accounts do |t|
      t.references :mail_domain, null: false, foreign_key: true
      t.string :local_part, null: false
      # SHA-512 crypt digest handed to Dovecot; the plaintext password is
      # never stored (see MailAccount#password=).
      t.string :password_hash, null: false
      # When this row was last written into the mail server's maps by
      # MailboxProvisioner -- nil (or older than updated_at) means the
      # address exists in the DB but not yet on the server.
      t.datetime :synced_at
      t.datetime :last_test_sent_at
      t.string :last_test_to
      t.boolean :last_test_succeeded
      t.text :last_test_error

      t.timestamps
    end
    add_index :mail_accounts, [:mail_domain_id, :local_part], unique: true
  end
end
