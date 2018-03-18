# frozen_string_literal: true

# Create file resource thumbnails table for storing thumbnails of files
class CreateFileResourceThumbnails < ActiveRecord::Migration[5.1]
  def change
    create_table :file_resource_thumbnails do |t|
      t.integer :provider_id, null: false
      t.text :external_id, null: false
      t.text :version_id, null: false
      t.attachment :image, null: false

      # Only allow one thumbnail per version_id (scoped to provider &
      # external ID)
      t.index %i[provider_id external_id version_id],
              name: 'index_thumbnails_on_file_resource_identifier',
              unique: true

      t.timestamps
    end
  end
end
