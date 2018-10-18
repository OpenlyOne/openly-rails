# frozen_string_literal: true

# Create table for storing file resource backups
class CreateFileResourceBackups < ActiveRecord::Migration[5.1]
  def change
    create_table :file_resource_backups do |t|
      t.belongs_to :file_resource_snapshot, foreign_key: true,
                                            null: false,
                                            index: { unique: true }
      t.belongs_to :archive, foreign_key: { to_table: :project_archives },
                             null: false
      t.belongs_to :file_resource, foreign_key: true, null: false

      t.timestamps
    end
  end
end
