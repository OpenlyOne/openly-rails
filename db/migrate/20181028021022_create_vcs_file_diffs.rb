# frozen_string_literal: true

class CreateVcsFileDiffs < ActiveRecord::Migration[5.2]
  def change
    create_table :vcs_file_diffs do |t|
      t.belongs_to :commit, null: false, foreign_key: { to_table: :vcs_commits }
      t.belongs_to :new_snapshot, foreign_key: { to_table: :vcs_file_snapshots }
      t.belongs_to :old_snapshot, foreign_key: { to_table: :vcs_file_snapshots }
      t.text :first_three_ancestors, array: true, null: false

      t.timestamps
    end
  end
end
