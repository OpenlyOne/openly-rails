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

ActiveRecord::Schema.define(version: 20180212022524) do

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

  create_table "file_resource_snapshots", force: :cascade do |t|
    t.bigint "file_resource_id", null: false
    t.bigint "parent_id"
    t.text "name", null: false
    t.text "content_version", null: false
    t.text "external_id", null: false
    t.string "mime_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id", "content_version", "mime_type", "name", "parent_id"], name: "index_file_resource_snapshots_on_metadata", unique: true
    t.index ["external_id", "content_version", "mime_type", "name"], name: "index_file_resource_snapshots_on_metadata_without_parent", unique: true, where: "(parent_id IS NULL)"
    t.index ["file_resource_id"], name: "index_file_resource_snapshots_on_file_resource_id"
    t.index ["parent_id"], name: "index_file_resource_snapshots_on_parent_id"
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
    t.index ["parent_id"], name: "index_file_resources_on_parent_id"
    t.index ["provider_id", "external_id"], name: "index_file_resources_on_provider_id_and_external_id", unique: true
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
    t.index ["account_id"], name: "index_profiles_on_account_id", unique: true
    t.index ["handle"], name: "index_profiles_on_handle", unique: true
  end

  create_table "profiles_projects", id: false, force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.bigint "project_id", null: false
    t.index ["profile_id"], name: "index_profiles_projects_on_profile_id"
    t.index ["project_id", "profile_id"], name: "index_profiles_projects_on_project_id_and_profile_id", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.string "title", null: false
    t.string "owner_type", null: false
    t.bigint "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.citext "slug", null: false
    t.text "description"
    t.citext "tags", default: [], array: true
    t.index ["owner_type", "owner_id", "slug"], name: "index_projects_on_owner_type_and_owner_id_and_slug", unique: true
    t.index ["owner_type", "owner_id"], name: "index_projects_on_owner_type_and_owner_id"
  end

  create_table "signups", force: :cascade do |t|
    t.text "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "file_resource_snapshots", "file_resources", column: "parent_id"
  add_foreign_key "file_resources", "file_resources", column: "parent_id"
  add_foreign_key "profiles", "accounts"
end
