# frozen_string_literal: true

# Create table for associating revisions to file resources & snapshots
# (committed files)
class CreateCommittedFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :committed_files do |t|
      t.belongs_to :revision, null: false, index: false, foreign_key: true
      t.belongs_to :file_resource, null: false, foreign_key: true
      t.belongs_to :file_resource_snapshot, null: false, foreign_key: true

      # Each file can exist only once per revision
      t.index %i[revision_id file_resource_id], unique: true

      t.timestamps
    end
  end
end
