# rubocop:disable Metrics/ClassLength
class DropOldModels < ActiveRecord::Migration[5.2]
  def up
    tables = %i[committed_files file_diffs file_resource_backups
                file_resource_snapshots file_resource_thumbnails
                file_resources project_archives revisions staged_files]

    tables.each do |table|
      raise "Table #{table} still has data" unless empty_table?(table)
    end

    # Remove foreign keys
    remove_foreign_key :committed_files, :file_resource_snapshots
    remove_foreign_key :committed_files, :file_resources
    remove_foreign_key :committed_files, :revisions
    remove_foreign_key :file_diffs, :file_resource_snapshots
    remove_foreign_key :file_diffs, :file_resource_snapshots
    remove_foreign_key :file_diffs, :file_resources
    remove_foreign_key :file_diffs, :revisions
    remove_foreign_key :file_resource_backups, :file_resource_snapshots
    remove_foreign_key :file_resource_backups, :file_resources
    remove_foreign_key :file_resource_backups, :project_archives
    remove_foreign_key :file_resource_snapshots, :file_resource_thumbnails
    remove_foreign_key :file_resource_snapshots, :file_resources
    remove_foreign_key :file_resources, :file_resource_snapshots
    remove_foreign_key :file_resources, :file_resource_thumbnails
    remove_foreign_key :file_resources, :file_resources
    remove_foreign_key :project_archives, :file_resources
    remove_foreign_key :project_archives, :projects
    remove_foreign_key :revisions, :profiles
    remove_foreign_key :revisions, :projects
    remove_foreign_key :revisions, :revisions
    remove_foreign_key :staged_files, :file_resources
    remove_foreign_key :staged_files, :projects

    # Remove tables
    tables.each { |table| drop_table(table) }
  end

  def empty_table?(table)
    ActiveRecord::Base
      .connection
      .execute("select count(*) from #{table}")[0]
      .fetch('count')
      .zero?
  end

  def down
    # Copied from schema
    # rubocop:disable all
    create_table "committed_files", force: :cascade do |t|
      t.bigint "revision_id", null: false
      t.bigint "file_resource_id", null: false
      t.bigint "file_resource_snapshot_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["file_resource_id"], name: "index_committed_files_on_file_resource_id"
      t.index ["file_resource_snapshot_id"], name: "index_committed_files_on_file_resource_snapshot_id"
      t.index ["revision_id", "file_resource_id"], name: "index_committed_files_on_revision_id_and_file_resource_id", unique: true
    end

    create_table "file_diffs", force: :cascade do |t|
      t.bigint "revision_id", null: false
      t.bigint "file_resource_id", null: false
      t.bigint "current_snapshot_id"
      t.bigint "previous_snapshot_id"
      t.text "first_three_ancestors", null: false, array: true
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["current_snapshot_id"], name: "index_file_diffs_on_current_snapshot_id"
      t.index ["file_resource_id"], name: "index_file_diffs_on_file_resource_id"
      t.index ["previous_snapshot_id"], name: "index_file_diffs_on_previous_snapshot_id"
      t.index ["revision_id", "file_resource_id"], name: "index_file_diffs_on_revision_id_and_file_resource_id", unique: true
    end

    create_table "file_resource_backups", force: :cascade do |t|
      t.bigint "file_resource_snapshot_id", null: false
      t.bigint "archive_id", null: false
      t.bigint "file_resource_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["archive_id"], name: "index_file_resource_backups_on_archive_id"
      t.index ["file_resource_id"], name: "index_file_resource_backups_on_file_resource_id"
      t.index ["file_resource_snapshot_id"], name: "index_file_resource_backups_on_file_resource_snapshot_id", unique: true
    end

    create_table "file_resource_snapshots", force: :cascade do |t|
      t.bigint "file_resource_id", null: false
      t.bigint "parent_id"
      t.text "name", null: false
      t.text "content_version", null: false
      t.text "external_id", null: false
      t.string "mime_type", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.bigint "thumbnail_id"
      t.index ["external_id", "content_version", "mime_type", "name", "parent_id"], name: "index_file_resource_snapshots_on_metadata", unique: true
      t.index ["external_id", "content_version", "mime_type", "name"], name: "index_file_resource_snapshots_on_metadata_without_parent", unique: true, where: "(parent_id IS NULL)"
      t.index ["file_resource_id"], name: "index_file_resource_snapshots_on_file_resource_id"
      t.index ["parent_id"], name: "index_file_resource_snapshots_on_parent_id"
      t.index ["thumbnail_id"], name: "index_file_resource_snapshots_on_thumbnail_id"
    end

    create_table "file_resource_thumbnails", force: :cascade do |t|
      t.integer "provider_id", null: false
      t.text "external_id", null: false
      t.text "version_id", null: false
      t.string "image_file_name", null: false
      t.string "image_content_type", null: false
      t.integer "image_file_size", null: false
      t.datetime "image_updated_at", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["provider_id", "external_id", "version_id"], name: "index_thumbnails_on_file_resource_identifier", unique: true
    end

    create_table "file_resources", force: :cascade do |t|
      t.integer "provider_id", null: false
      t.text "external_id", null: false
      t.bigint "parent_id"
      t.text "name"
      t.text "content_version"
      t.string "mime_type"
      t.boolean "is_deleted", default: false, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.bigint "current_snapshot_id"
      t.bigint "thumbnail_id"
      t.index ["current_snapshot_id"], name: "index_file_resources_on_current_snapshot_id"
      t.index ["parent_id"], name: "index_file_resources_on_parent_id"
      t.index ["provider_id", "external_id"], name: "index_file_resources_on_provider_id_and_external_id", unique: true
      t.index ["thumbnail_id"], name: "index_file_resources_on_thumbnail_id"
    end

    create_table "project_archives", force: :cascade do |t|
      t.bigint "project_id", null: false
      t.bigint "file_resource_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["file_resource_id"], name: "index_project_archives_on_file_resource_id"
      t.index ["project_id"], name: "index_project_archives_on_project_id", unique: true
    end

    create_table "revisions", force: :cascade do |t|
      t.bigint "project_id", null: false
      t.bigint "parent_id"
      t.bigint "author_id", null: false
      t.boolean "is_published", default: false, null: false
      t.string "title"
      t.text "summary"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["author_id"], name: "index_revisions_on_author_id"
      t.index ["parent_id"], name: "index_revisions_on_parent_id"
      t.index ["parent_id"], name: "index_revisions_on_published_parent_id", unique: true, where: "(is_published IS TRUE)"
      t.index ["project_id"], name: "index_revisions_on_project_id"
      t.index ["project_id"], name: "index_revisions_on_published_root_revision", unique: true, where: "((parent_id IS NULL) AND (is_published IS TRUE))"
    end

    create_table "staged_files", force: :cascade do |t|
      t.bigint "project_id", null: false
      t.bigint "file_resource_id", null: false
      t.boolean "is_root", default: false, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["file_resource_id"], name: "index_staged_files_on_file_resource_id"
      t.index ["project_id", "file_resource_id"], name: "index_staged_files_on_project_id_and_file_resource_id", unique: true
      t.index ["project_id"], name: "index_staged_files_on_root", unique: true, where: "(is_root IS TRUE)"
    end

    # FOREIGN KEYS
    add_foreign_key "committed_files", "file_resource_snapshots"
    add_foreign_key "committed_files", "file_resources"
    add_foreign_key "committed_files", "revisions"
    add_foreign_key "file_diffs", "file_resource_snapshots", column: "current_snapshot_id"
    add_foreign_key "file_diffs", "file_resource_snapshots", column: "previous_snapshot_id"
    add_foreign_key "file_diffs", "file_resources"
    add_foreign_key "file_diffs", "revisions"
    add_foreign_key "file_resource_backups", "file_resource_snapshots"
    add_foreign_key "file_resource_backups", "file_resources"
    add_foreign_key "file_resource_backups", "project_archives", column: "archive_id"
    add_foreign_key "file_resource_snapshots", "file_resource_thumbnails", column: "thumbnail_id"
    add_foreign_key "file_resource_snapshots", "file_resources", column: "parent_id"
    add_foreign_key "file_resources", "file_resource_snapshots", column: "current_snapshot_id"
    add_foreign_key "file_resources", "file_resource_thumbnails", column: "thumbnail_id"
    add_foreign_key "file_resources", "file_resources", column: "parent_id"
    add_foreign_key "project_archives", "file_resources"
    add_foreign_key "project_archives", "projects"
    add_foreign_key "revisions", "profiles", column: "author_id"
    add_foreign_key "revisions", "projects"
    add_foreign_key "revisions", "revisions", column: "parent_id"
    add_foreign_key "staged_files", "file_resources"
    add_foreign_key "staged_files", "projects"
    # rubocop:enable all
  end
end
# rubocop:enable Metrics/ClassLength
