class RenameFileThumbnailsToThumbnails < ActiveRecord::Migration[5.2]
  def up
    rename_table :vcs_thumbnails, :vcs_thumbnails

    # rename attachment directory
    FileUtils.mv(
      old_path_for_file_thumbnail_storage,
      new_path_for_file_thumbnail_storage
    )
  end

  def down
    rename_table :vcs_thumbnails, :vcs_thumbnails

    # rename attachment directory
    FileUtils.mv(
      new_path_for_file_thumbnail_storage,
      old_path_for_file_thumbnail_storage
    )
  end

  private

  def old_path_for_file_thumbnail_storage
    Rails.root.join(Settings.attachment_storage, 'vcs', 'thumbnails')
  end

  def new_path_for_file_thumbnail_storage
    Rails.root.join(Settings.attachment_storage, 'vcs', 'thumbnails')
  end
end
