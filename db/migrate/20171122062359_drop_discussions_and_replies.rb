# frozen_string_literal: true

# Remove discussions and replies as well as discussion counts
class DropDiscussionsAndReplies < ActiveRecord::Migration[5.1]
  def up
    drop_table 'replies'
    drop_table 'discussions'

    remove_column :projects, :suggestions_count
    remove_column :projects, :issues_count
    remove_column :projects, :questions_count
  end

  def down
    create_table :discussions do |t|
      t.string :title, null: false
      t.string :type, null: false
      t.integer :initiator_id, index: true, null: false
      t.foreign_key :profiles, column: :initiator_id
      t.belongs_to :project, index: true, foreign_key: true, null: false
      t.integer :scoped_id, null: false

      t.timestamps

      t.index :scoped_id
    end

    create_table :replies do |t|
      t.text :content, null: false
      t.integer :author_id, index: true, null: false
      t.foreign_key :profiles, column: :author_id
      t.references :discussion, foreign_key: true, null: false

      t.timestamps
    end

    add_column :projects, :suggestions_count, :integer, default: 0, null: false
    add_column :projects, :issues_count, :integer, default: 0, null: false
    add_column :projects, :questions_count, :integer, default: 0, null: false
  end
end
