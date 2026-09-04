class AddIpAddressToShopInquiries < ActiveRecord::Migration[8.1]
  def change
    add_column :shop_inquiries, :ip_address, :string
  end
end
