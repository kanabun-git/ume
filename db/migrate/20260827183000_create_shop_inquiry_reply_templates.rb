class CreateShopInquiryReplyTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_inquiry_reply_templates do |t|
      t.text :body, null: false

      t.timestamps
    end
  end
end
