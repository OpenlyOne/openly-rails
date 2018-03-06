# frozen_string_literal: true

# Create table for associating projects to file resources (staged files)
class CreateStagedFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :staged_files do |t|
      t.belongs_to :project, foreign_key: true, null: false, index: false
      t.belongs_to :file_resource, foreign_key: true, null: false
      t.boolean :is_root, null: false, default: false

      t.index %i[project_id file_resource_id], unique: true

      t.index :project_id,
              name: 'index_staged_files_on_root',
              unique: true,
              where: 'is_root IS TRUE'

      t.timestamps
    end
  end
end
