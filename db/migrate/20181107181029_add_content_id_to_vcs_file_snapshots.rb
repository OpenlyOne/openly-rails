class AddContentIdToVcsFileSnapshots < ActiveRecord::Migration[5.2]
  def up
    add_column :vcs_file_snapshots, :content_id, :bigint, null: true
    add_foreign_key :vcs_file_snapshots, :vcs_contents, column: :content_id

    # migrate snapshots to use VCS::Content
    Rake::Task['data_migration:file_snapshots_content'].invoke
  end

  def down
    remove_foreign_key :vcs_file_snapshots, :vcs_contents
    remove_column :vcs_file_snapshots, :content_id
  end
end
