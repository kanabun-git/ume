class AddMemberToReviews < ActiveRecord::Migration[8.1]
  def change
    add_reference :reviews, :member, null: true, foreign_key: true
  end
end
