# frozen_string_literal: true

class CreateVcsCommittedFiles < ActiveRecord::Migration[5.2]
  def change
    create_table :vcs_committed_files do |t|
      t.belongs_to :commit, null: false, foreign_key: { to_table: :vcs_commits }
      t.belongs_to :file_snapshot,
                   null: false,
                   foreign_key: { to_table: :vcs_file_snapshots }

      # Each snapshot can exist only once per revision
      t.index %i[commit_id file_snapshot_id], unique: true

      t.timestamps
    end
  end
end
