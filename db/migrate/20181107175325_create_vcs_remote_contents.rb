class CreateVcsRemoteContents < ActiveRecord::Migration[5.2]
  def change
    create_table :vcs_remote_contents do |t|
      t.belongs_to :repository, foreign_key: { to_table: :vcs_repositories },
                                null: false
      t.belongs_to :content, foreign_key: { to_table: :vcs_contents },
                             null: false
      t.text :remote_file_id, null: false
      t.text :remote_content_version_id, null: false

      t.index %i[repository_id remote_file_id remote_content_version_id],
              name: 'index_vcs_remote_contents_on_remote_file_contents',
              unique: true

      t.timestamps
    end
  end
end
