# frozen_string_literal: true

# Suggestions, Issues, Questions in projects
class CreateDiscussions < ActiveRecord::Migration[5.1]
  def change
    create_table :discussions do |t|
      t.string :title, null: false
      t.string :type, null: false
      t.integer :initiator_id, index: true, null: false
      t.foreign_key :users, column: :initiator_id
      t.belongs_to :project, index: true, foreign_key: true, null: false

      t.timestamps
    end
  end
end
