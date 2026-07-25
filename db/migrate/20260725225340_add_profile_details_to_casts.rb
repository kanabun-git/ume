class AddProfileDetailsToCasts < ActiveRecord::Migration[7.2]
  def change
    add_column :casts, :is_trial, :boolean, default: false, null: false
    add_column :casts, :manager_recommended, :boolean, default: false, null: false
    add_column :casts, :appeal_comment, :text
    add_column :casts, :manager_comment, :text
    add_column :casts, :selling_points, :text
    add_column :casts, :qa_message, :text
    add_column :casts, :zodiac_sign, :string
    add_column :casts, :blood_type, :string
  end
end
