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

ActiveRecord::Schema.define(version: 20171018143015) do

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

  create_table "discussions", force: :cascade do |t|
    t.string "title", null: false
    t.string "type", null: false
    t.integer "initiator_id", null: false
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "scoped_id", null: false
    t.index ["initiator_id"], name: "index_discussions_on_initiator_id"
    t.index ["project_id"], name: "index_discussions_on_project_id"
    t.index ["scoped_id"], name: "index_discussions_on_scoped_id"
  end

  create_table "handles", force: :cascade do |t|
    t.citext "identifier", null: false
    t.string "profile_type", null: false
    t.bigint "profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_handles_on_identifier", unique: true
    t.index ["profile_type", "profile_id"], name: "index_handles_on_profile_type_and_profile_id", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "account_id"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color_scheme", default: "indigo base", null: false
    t.string "type", null: false
    t.index ["account_id"], name: "index_profiles_on_account_id", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.string "title", null: false
    t.string "owner_type", null: false
    t.bigint "owner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.citext "slug", null: false
    t.integer "suggestions_count", default: 0, null: false
    t.integer "issues_count", default: 0, null: false
    t.integer "questions_count", default: 0, null: false
    t.integer "files_count", default: 0, null: false
    t.index ["owner_type", "owner_id", "slug"], name: "index_projects_on_owner_type_and_owner_id_and_slug", unique: true
    t.index ["owner_type", "owner_id"], name: "index_projects_on_owner_type_and_owner_id"
  end

  create_table "replies", force: :cascade do |t|
    t.text "content", null: false
    t.integer "author_id", null: false
    t.bigint "discussion_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_replies_on_author_id"
    t.index ["discussion_id"], name: "index_replies_on_discussion_id"
  end

  add_foreign_key "discussions", "profiles", column: "initiator_id"
  add_foreign_key "discussions", "projects"
  add_foreign_key "profiles", "accounts"
  add_foreign_key "replies", "discussions"
  add_foreign_key "replies", "profiles", column: "author_id"
end
