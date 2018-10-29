class CreateVcsFileThumbnails < ActiveRecord::Migration[5.2]
  def change
    create_table :vcs_file_thumbnails do |t|
      t.text :external_id, null: false
      t.text :version_id, null: false
      t.attachment :image

      t.timestamps
    end
  end
end
