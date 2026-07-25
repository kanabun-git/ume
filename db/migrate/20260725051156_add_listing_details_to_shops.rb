class AddListingDetailsToShops < ActiveRecord::Migration[7.2]
  def change
    add_column :shops, :chain_name, :string
    add_column :shops, :price_note, :string
    add_column :shops, :transportation_fee_note, :string
    add_column :shops, :coverage_area_note, :string
    add_column :shops, :coupon_description, :text
    add_column :shops, :recruiting_message, :text
    add_column :shops, :editor_review, :text
    add_column :shops, :online_reservation, :boolean, default: false, null: false
    add_column :shops, :visit_point_program, :boolean, default: false, null: false
    add_column :shops, :coupon_available, :boolean, default: false, null: false
    add_column :shops, :event_ongoing, :boolean, default: false, null: false
    add_column :shops, :recruiting_cast, :boolean, default: false, null: false
    add_column :shops, :recruiting_staff, :boolean, default: false, null: false
  end
end
