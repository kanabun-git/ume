class AddHiddenToActiveStorageAttachments < ActiveRecord::Migration[7.2]
  def change
    add_column :active_storage_attachments, :hidden, :boolean, default: false, null: false
  end
end
