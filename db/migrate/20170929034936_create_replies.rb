# frozen_string_literal: true

# Replies to discussions (suggestions, issues, questions)
class CreateReplies < ActiveRecord::Migration[5.1]
  def change
    create_table :replies do |t|
      t.text :content, null: false
      t.integer :author_id, index: true, null: false
      t.foreign_key :users, column: :author_id
      t.references :discussion, foreign_key: true, null: false

      t.timestamps
    end
  end
end
