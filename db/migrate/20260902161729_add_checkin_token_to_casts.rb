class AddCheckinTokenToCasts < ActiveRecord::Migration[8.1]
  def up
    add_column :casts, :checkin_token, :string
    add_index :casts, :checkin_token, unique: true

    Cast.reset_column_information
    Cast.find_each do |cast|
      cast.update_column(:checkin_token, SecureRandom.base58(24)) if cast.checkin_token.blank?
    end
  end

  def down
    remove_index :casts, :checkin_token
    remove_column :casts, :checkin_token
  end
end
