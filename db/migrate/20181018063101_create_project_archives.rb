# frozen_string_literal: true

# Create archives for storing file copies/blobs
class CreateProjectArchives < ActiveRecord::Migration[5.1]
  def change
    create_table :project_archives do |t|
      t.belongs_to :project, foreign_key: true, null: false,
                             index: { unique: true }
      t.belongs_to :file_resource, foreign_key: true, null: false

      t.timestamps
    end
  end
end
