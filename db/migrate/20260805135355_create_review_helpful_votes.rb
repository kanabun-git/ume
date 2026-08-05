class CreateReviewHelpfulVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :review_helpful_votes do |t|
      t.references :review, null: false, foreign_key: true
      t.string :ip_address, null: false

      t.timestamps
    end
    add_index :review_helpful_votes, [:review_id, :ip_address], unique: true
  end
end
