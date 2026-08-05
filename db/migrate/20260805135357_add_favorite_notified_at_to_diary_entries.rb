class AddFavoriteNotifiedAtToDiaryEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :diary_entries, :favorite_notified_at, :datetime
  end
end
