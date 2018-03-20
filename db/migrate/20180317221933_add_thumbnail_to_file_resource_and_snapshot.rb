# frozen_string_literal: true

# Add thumbnail_id column to file resources & file resource snapshots
class AddThumbnailToFileResourceAndSnapshot < ActiveRecord::Migration[5.1]
  def change
    add_reference :file_resources, :thumbnail,
                  null: true,
                  foreign_key: { to_table: :file_resource_thumbnails }
    add_reference :file_resource_snapshots, :thumbnail,
                  null: true,
                  foreign_key: { to_table: :file_resource_thumbnails }
  end
end
