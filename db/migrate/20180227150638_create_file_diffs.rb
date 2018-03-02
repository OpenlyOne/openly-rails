# frozen_string_literal: true

# Create FileDiffs table for storing pre-generated file diffs (so that we do not
# have to create them at run-time)
class CreateFileDiffs < ActiveRecord::Migration[5.1]
  def change
    create_table :file_diffs do |t|
      t.belongs_to :revision, foreign_key: true, null: false, index: false
      t.belongs_to :file_resource, foreign_key: true, null: false
      t.belongs_to :current_snapshot,
                   foreign_key: { to_table: :file_resource_snapshots },
                   null: true
      t.belongs_to :previous_snapshot,
                   foreign_key: { to_table: :file_resource_snapshots },
                   null: true
      t.text :first_three_ancestors, array: true, null: false

      # Do not allow duplicate file resources in the same revision
      t.index %i[revision_id file_resource_id], unique: true

      t.timestamps
    end
  end
end
