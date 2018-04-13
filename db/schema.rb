# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180413034654) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "citext"

  create_table "accounts", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "remember_created_at"
    t.index ["email"], name: "index_accounts_on_email", unique: true
  end

  create_table "ahoy_events", force: :cascade do |t|
    t.bigint "visit_id"
    t.bigint "user_id"
    t.string "name"
    t.jsonb "properties"
    t.datetime "time"
    t.index "properties jsonb_path_ops", name: "index_ahoy_events_on_properties_jsonb_path_ops", using: :gin
    t.index ["name", "time"], name: "index_ahoy_events_on_name_and_time"
    t.index ["user_id"], name: "index_ahoy_events_on_user_id"
    t.index ["visit_id"], name: "index_ahoy_events_on_visit_id"
  end

  create_table "ahoy_visits", force: :cascade do |t|
    t.string "visit_token"
    t.string "visitor_token"
    t.bigint "user_id"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "referring_domain"
    t.string "search_keyword"
    t.text "landing_page"
    t.string "browser"
    t.string "os"
    t.string "device_type"
    t.string "country"
    t.string "region"
    t.string "city"
    t.string "utm_source"
    t.string "utm_medium"
    t.string "utm_term"
    t.string "utm_content"
    t.string "utm_campaign"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_ahoy_visits_on_user_id"
    t.index ["visit_token"], name: "index_ahoy_visits_on_visit_token", unique: true
  end

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

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.bigint "delayed_reference_id"
    t.string "delayed_reference_type"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
    t.index ["queue"], name: "index_delayed_jobs_on_queue"
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

  create_table "notifications", force: :cascade do |t|
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.string "notifiable_type", null: false
    t.bigint "notifiable_id", null: false
    t.string "notifier_type"
    t.bigint "notifier_id"
    t.string "group_type"
    t.bigint "group_id"
    t.integer "group_owner_id"
    t.string "key", null: false
    t.text "parameters"
    t.datetime "opened_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_owner_id"], name: "index_notifications_on_group_owner_id"
    t.index ["group_type", "group_id"], name: "index_notifications_on_group_type_and_group_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["notifier_type", "notifier_id"], name: "index_notifications_on_notifier_type_and_notifier_id"
    t.index ["target_type", "target_id"], name: "index_notifications_on_target_type_and_target_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "account_id"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color_scheme", default: "indigo base", null: false
    t.string "type", null: false
    t.citext "handle", null: false
    t.string "picture_file_name"
    t.string "picture_content_type"
    t.integer "picture_file_size"
    t.datetime "picture_updated_at"
    t.text "about"
    t.text "location"
    t.text "link_to_website"
    t.text "link_to_facebook"
    t.text "link_to_twitter"
    t.index ["account_id"], name: "index_profiles_on_account_id", unique: true
    t.index ["handle"], name: "index_profiles_on_handle", unique: true
  end

  create_table "profiles_projects", id: false, force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.bigint "project_id", null: false
    t.index ["profile_id"], name: "index_profiles_projects_on_profile_id"
    t.index ["project_id", "profile_id"], name: "index_profiles_projects_on_project_id_and_profile_id", unique: true
  end

  create_table "project_setups", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.boolean "is_completed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_setups_on_project_id", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.citext "slug", null: false
    t.text "description"
    t.citext "tags", default: [], array: true
    t.boolean "is_public", default: false, null: false
    t.bigint "owner_id", null: false
    t.index ["owner_id", "slug"], name: "index_projects_on_owner_id_and_slug", unique: true
    t.index ["owner_id"], name: "index_projects_on_owner_id"
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

  create_table "signups", force: :cascade do |t|
    t.text "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  add_foreign_key "committed_files", "file_resource_snapshots"
  add_foreign_key "committed_files", "file_resources"
  add_foreign_key "committed_files", "revisions"
  add_foreign_key "file_diffs", "file_resource_snapshots", column: "current_snapshot_id"
  add_foreign_key "file_diffs", "file_resource_snapshots", column: "previous_snapshot_id"
  add_foreign_key "file_diffs", "file_resources"
  add_foreign_key "file_diffs", "revisions"
  add_foreign_key "file_resource_snapshots", "file_resource_thumbnails", column: "thumbnail_id"
  add_foreign_key "file_resource_snapshots", "file_resources", column: "parent_id"
  add_foreign_key "file_resources", "file_resource_snapshots", column: "current_snapshot_id"
  add_foreign_key "file_resources", "file_resource_thumbnails", column: "thumbnail_id"
  add_foreign_key "file_resources", "file_resources", column: "parent_id"
  add_foreign_key "profiles", "accounts"
  add_foreign_key "project_setups", "projects"
  add_foreign_key "revisions", "profiles", column: "author_id"
  add_foreign_key "revisions", "projects"
  add_foreign_key "revisions", "revisions", column: "parent_id"
  add_foreign_key "staged_files", "file_resources"
  add_foreign_key "staged_files", "projects"
end
