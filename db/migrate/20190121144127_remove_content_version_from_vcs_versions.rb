class RemoveContentVersionFromVcsVersions < ActiveRecord::Migration[5.2]
  def change
    remove_column :vcs_versions, :content_version, :text, null: false
  end
end
