class CreateReviewReplyTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :review_reply_templates do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body, null: false

      t.timestamps
    end
  end
end
