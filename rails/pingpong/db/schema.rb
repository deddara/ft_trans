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

ActiveRecord::Schema.define(version: 2021_01_31_153250) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "friendships", force: :cascade do |t|
    t.integer "friendable_id"
    t.integer "friend_id"
    t.integer "blocker_id"
    t.boolean "pending", default: true
    t.index ["friendable_id", "friend_id"], name: "index_friendships_on_friendable_id_and_friend_id", unique: true
  end

  create_table "game_rooms", force: :cascade do |t|
    t.bigint "p1_id"
    t.bigint "p2_id"
    t.string "name"
    t.integer "status", default: 0
    t.boolean "rating", default: false
    t.boolean "private", default: false
    t.string "passcode", default: ""
    t.string "ball_color", default: "#ffffff"
    t.string "bg_color", default: "#000000"
    t.string "paddle_color", default: "#ffffff"
    t.float "paddle_speed", default: 6.0
    t.float "paddle_p1_dy", default: 0.0
    t.float "paddle_p2_dy", default: 0.0
    t.float "paddle_p1_y", default: 120.0
    t.float "paddle_p2_y", default: 120.0
    t.boolean "ball_down_mode", default: false
    t.boolean "ball_speedup_mode", default: false
    t.boolean "random_mode", default: false
    t.float "ball_radius", default: 10.0
    t.float "ball_size", default: 2.0
    t.float "ball_x", default: 358.0
    t.float "ball_y", default: 173.0
    t.float "ball_dx", default: 2.0
    t.float "ball_dy", default: -2.0
    t.float "speed_rate", default: 1.0
    t.integer "p1_score", default: 0
    t.integer "p2_score", default: 0
    t.boolean "war_time", default: false
    t.boolean "resetting", default: false
    t.datetime "started"
    t.datetime "ended"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["p1_id"], name: "index_game_rooms_on_p1_id"
    t.index ["p2_id"], name: "index_game_rooms_on_p2_id"
  end

  create_table "guild_invites", force: :cascade do |t|
    t.bigint "guild_id"
    t.bigint "user_id"
    t.integer "status", default: 0
    t.integer "dir", default: 0
    t.bigint "invited_by_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["guild_id"], name: "index_guild_invites_on_guild_id"
    t.index ["invited_by_id"], name: "index_guild_invites_on_invited_by_id"
    t.index ["user_id"], name: "index_guild_invites_on_user_id"
  end

  create_table "guild_members", force: :cascade do |t|
    t.boolean "owner", default: false
    t.boolean "officer", default: false
    t.bigint "guild_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["guild_id"], name: "index_guild_members_on_guild_id"
    t.index ["user_id"], name: "index_guild_members_on_user_id"
  end

  create_table "guilds", force: :cascade do |t|
    t.string "name"
    t.string "anagram"
    t.string "description"
    t.integer "points", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "invitations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "friend_id"
    t.boolean "confirmed", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_invitations_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "recipient_id"
    t.string "action"
    t.string "notifiable_type"
    t.string "service_info"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "status", default: 0
    t.integer "score", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "nickname"
    t.string "provider"
    t.string "uid"
    t.string "image"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider"], name: "index_users_on_provider"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid"], name: "index_users_on_uid"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "game_rooms", "users", column: "p1_id"
  add_foreign_key "game_rooms", "users", column: "p2_id"
  add_foreign_key "guild_members", "guilds"
  add_foreign_key "guild_members", "users"
  add_foreign_key "invitations", "users"
  add_foreign_key "notifications", "users"
end
