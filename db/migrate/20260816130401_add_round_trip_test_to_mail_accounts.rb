class AddRoundTripTestToMailAccounts < ActiveRecord::Migration[8.1]
  def change
    # 送受信テスト(自分宛にメールを送り、IMAPで実際に届いたか確認する)の結果。
    # 送信のみを試す既存の last_test_* (外部の任意アドレス宛) とは別に記録する。
    add_column :mail_accounts, :last_round_trip_tested_at, :datetime
    add_column :mail_accounts, :last_round_trip_succeeded, :boolean
    add_column :mail_accounts, :last_round_trip_error, :text
  end
end
