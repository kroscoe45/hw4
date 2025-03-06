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

ActiveRecord::Schema[8.0].define(version: 2025_03_06_185245) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "initial_schemas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "playlists", force: :cascade do |t|
    t.bigint "owner_id", null: false
    t.string "title", null: false
    t.boolean "is_public", default: false, null: false
    t.string "tracks", default: [], array: true
    t.string "tags", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_public"], name: "index_playlists_on_is_public"
    t.index ["owner_id"], name: "index_playlists_on_owner_id"
    t.index ["tags"], name: "index_playlists_on_tags", using: :gin
    t.index ["tracks"], name: "index_playlists_on_tracks", using: :gin
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.jsonb "attached_to", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attached_to"], name: "index_tags_on_attached_to", using: :gin
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.check_constraint "char_length(name::text) >= 2 AND char_length(name::text) <= 20", name: "check_tag_name_length"
  end

  create_table "tracks", force: :cascade do |t|
    t.string "title", null: false
    t.string "artist", null: false
    t.datetime "added_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((artist)::text) varchar_pattern_ops", name: "index_tracks_on_lowercase_artist"
    t.index "lower((title)::text) varchar_pattern_ops", name: "index_tracks_on_lowercase_title"
    t.index ["artist", "title"], name: "index_tracks_on_artist_and_title", unique: true
    t.index ["artist"], name: "index_tracks_on_artist"
    t.index ["title"], name: "index_tracks_on_title"
  end

  create_table "users", force: :cascade do |t|
    t.string "auth0_id", null: false
    t.string "roles", default: "user", null: false
    t.string "username", limit: 16
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auth0_id"], name: "index_users_on_auth0_id", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true, where: "(username IS NOT NULL)"
    t.check_constraint "roles::text = ANY (ARRAY['user'::character varying, 'admin'::character varying]::text[])", name: "check_valid_roles"
    t.check_constraint "username IS NULL OR username::text ~ '^[A-Za-z0-9_-]{1,16}$'::text", name: "check_username_format"
  end

  add_foreign_key "playlists", "users", column: "owner_id"
end
