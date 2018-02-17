# frozen_string_literal: true

# Add column for storing the file resource's current snapshot
class AddCurrentSnapshotToFileResources < ActiveRecord::Migration[5.1]
  def change
    add_reference :file_resources,
                  :current_snapshot,
                  foreign_key: { to_table: :file_resource_snapshots }
  end
end
