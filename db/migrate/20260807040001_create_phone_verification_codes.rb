class CreatePhoneVerificationCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :phone_verification_codes do |t|
      t.references :member, null: false, foreign_key: true
      t.string :phone_number, null: false
      t.string :code, null: false
      t.datetime :expires_at, null: false
      t.datetime :consumed_at

      t.timestamps
    end
  end
end
