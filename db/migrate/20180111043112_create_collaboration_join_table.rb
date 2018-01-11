# frozen_string_literal: true

# Table for collaborators (profiles) and collaborations (projects)
class CreateCollaborationJoinTable < ActiveRecord::Migration[5.1]
  def change
    create_join_table :profiles, :projects do |t|
      t.index :profile_id
      t.index %w[project_id profile_id], unique: true
    end
  end
end
