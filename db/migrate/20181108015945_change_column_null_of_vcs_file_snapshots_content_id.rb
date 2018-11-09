class ChangeColumnNullOfVcsFileSnapshotsContentId < ActiveRecord::Migration[5.2]
  def up
    change_column_null :vcs_file_snapshots, :content_id, false
  end

  def down
    change_column_null :vcs_file_snapshots, :content_id, true
  end
end
