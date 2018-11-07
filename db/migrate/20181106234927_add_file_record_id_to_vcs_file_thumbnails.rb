# frozen_string_literal: true

class AddFileRecordIdToVcsFileThumbnails < ActiveRecord::Migration[5.2]
  def up
    add_column :vcs_file_thumbnails, :file_record_id, :bigint,
               null: true, index: true
    add_foreign_key :vcs_file_thumbnails,
                    :vcs_file_records,
                    column: :file_record_id

    Rake::Task['data_migration:file_thumbnails'].invoke
  end

  def down
    remove_foreign_key :vcs_file_thumbnails, :vcs_file_records

    remove_column :vcs_file_thumbnails, :file_record_id
  end
end
