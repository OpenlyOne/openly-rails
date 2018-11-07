# frozen_string_literal: true

class ChangeColumnNullOfFileThumbnails < ActiveRecord::Migration[5.2]
  def up
    change_column_null :vcs_file_thumbnails, :file_record_id, false
  end

  def down
    change_column_null :vcs_file_thumbnails, :file_record_id, true
  end
end
