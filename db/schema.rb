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

ActiveRecord::Schema.define(version: 20171122062359) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "citext"

  create_table "accounts", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_accounts_on_email", unique: true
  end

  create_table "file_items", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "parent_id"
    t.string "google_drive_id", null: false
    t.text "name", null: false
    t.string "mime_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["google_drive_id"], name: "index_file_items_on_google_drive_id"
    t.index ["parent_id"], name: "index_file_items_on_parent_id"
    t.index ["project_id"], name: "index_file_items_on_project_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "account_id"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color_scheme", default: "indigo base", null: false
    t.string "type", null: false
    t.citext "handle", null: false
    t.index ["account_id"], name: "index_profiles_on_account_id", unique: true
    t.index ["handle"], name: "index_profiles_on_handle", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.string "title", null: false
    t.string "owner_type", null: false
    t.bigint "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.citext "slug", null: false
    t.index ["owner_type", "owner_id", "slug"], name: "index_projects_on_owner_type_and_owner_id_and_slug", unique: true
    t.index ["owner_type", "owner_id"], name: "index_projects_on_owner_type_and_owner_id"
  end

  add_foreign_key "file_items", "file_items", column: "parent_id"
  add_foreign_key "file_items", "projects"
  add_foreign_key "profiles", "accounts"
end
