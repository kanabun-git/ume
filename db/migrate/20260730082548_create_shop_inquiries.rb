class CreateShopInquiries < ActiveRecord::Migration[7.2]
  def change
    create_table :shop_inquiries do |t|
      t.string :shop_name, null: false
      t.string :contact_name, null: false
      t.string :email, null: false
      t.string :phone, null: false
      t.string :area_note
      t.text :message
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
