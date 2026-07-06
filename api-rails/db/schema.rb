# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_07_06_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "entries", force: :cascade do |t|
    t.bigint "topic_id", null: false
    t.bigint "created_by_id", null: false
    t.bigint "updated_by_id"
    t.datetime "occurred_at"
    t.string "kind"
    t.string "currency", default: "usd", null: false
    t.integer "amount", default: 0, null: false
    t.string "category"
    t.string "title"
    t.string "content"
    t.boolean "checked", default: false, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_entries_on_created_by_id"
    t.index ["deleted_at"], name: "index_entries_on_deleted_at"
    t.index ["topic_id"], name: "index_entries_on_topic_id"
    t.index ["updated_by_id"], name: "index_entries_on_updated_by_id"
  end

  create_table "topic_follows", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "topic_id", null: false
    t.datetime "followed_at"
    t.datetime "invited_at"
    t.jsonb "permissions", default: ["create", "edit"], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_topic_follows_on_topic_id"
    t.index ["user_id", "topic_id"], name: "index_topic_follows_on_user_id_and_topic_id", unique: true
    t.index ["user_id"], name: "index_topic_follows_on_user_id"
  end

  create_table "topics", force: :cascade do |t|
    t.string "title", null: false
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.jsonb "default_permissions", default: ["create", "edit"], null: false
    t.index ["deleted_at"], name: "index_topics_on_deleted_at"
    t.index ["token"], name: "index_topics_on_token", unique: true
    t.index ["user_id"], name: "index_topics_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "nick_name", null: false
    t.string "token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_guest", default: false, null: false
    t.string "password_digest"
    t.string "login_code"
    t.datetime "login_code_expires_at"
    t.datetime "terms_accepted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["token"], name: "index_users_on_token", unique: true
  end

  add_foreign_key "entries", "topics"
  add_foreign_key "entries", "users", column: "created_by_id"
  add_foreign_key "entries", "users", column: "updated_by_id"
  add_foreign_key "topic_follows", "topics"
  add_foreign_key "topic_follows", "users"
  add_foreign_key "topics", "users"
end
