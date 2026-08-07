class AddPhoneToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :phone_number, :string
    add_column :members, :phone_verified_at, :datetime
  end
end
