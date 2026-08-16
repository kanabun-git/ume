class AddPasswordDisplayToMailAccounts < ActiveRecord::Migration[8.1]
  def change
    # Holds the mailbox password in a form the management screen can show
    # back to the operator (メールソフトの設定に必要なため)。Encrypted at rest
    # by Active Record Encryption -- see MailAccount -- so a database dump or
    # backup never contains the plaintext.
    add_column :mail_accounts, :stored_password, :text

    # Hostname to put in a mail client's 受信/送信サーバー field, when it
    # differs from the domain itself (e.g. mail.example.com). Blank means
    # "use the domain as-is".
    add_column :mail_domains, :mail_server_host, :string
  end
end
