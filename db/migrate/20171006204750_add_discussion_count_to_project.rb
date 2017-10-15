# frozen_string_literal: true

# Replies to discussions (suggestions, issues, questions)
class AddDiscussionCountToProject < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :suggestions_count, :integer, default: 0, null: false
    add_column :projects, :issues_count, :integer, default: 0, null: false
    add_column :projects, :questions_count, :integer, default: 0, null: false
  end
end
