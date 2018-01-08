# frozen_string_literal: true

# Drop support for file items, no longer needed due to using Git repositories
class DropTableFileItems < ActiveRecord::Migration[5.1]
  def up
    drop_table 'file_items'
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def down
    create_table 'file_items' do |t|
      t.bigint 'project_id', null: false
      t.bigint 'parent_id'
      t.string 'google_drive_id', null: false
      t.text 'name', null: false
      t.string 'mime_type', null: false
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.bigint 'version', default: 0, null: false
      t.bigint 'version_at_last_commit', default: 0, null: false
      t.datetime 'modified_time'
      t.datetime 'modified_time_at_last_commit'
      t.bigint 'parent_id_at_last_commit'
      t.index ['google_drive_id'], name: 'index_file_items_on_google_drive_id'
      t.index ['parent_id'], name: 'index_file_items_on_parent_id'
      t.index ['project_id'], name: 'index_file_items_on_project_id'
    end

    add_foreign_key 'file_items', 'file_items', column: 'parent_id'
    add_foreign_key 'file_items', 'projects'
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
