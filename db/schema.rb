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

ActiveRecord::Schema[8.0].define(version: 2025_10_05_220410) do
  create_table "answers", force: :cascade do |t|
    t.integer "prompt_id", null: false
    t.integer "user_id", null: false
    t.integer "room_id", null: false
    t.string "text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["prompt_id", "room_id", "user_id"], name: "index_answers_on_prompt_id_and_room_id_and_user_id", unique: true
    t.index ["prompt_id"], name: "index_answers_on_prompt_id"
    t.index ["room_id"], name: "index_answers_on_room_id"
    t.index ["user_id"], name: "index_answers_on_user_id"
  end

  create_table "blanks", force: :cascade do |t|
    t.string "tags", null: false
    t.integer "story_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["story_id"], name: "index_blanks_on_story_id"
  end

  create_table "game_prompts", force: :cascade do |t|
    t.integer "game_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "prompt_id", null: false
    t.integer "blank_id", null: false
    t.index ["blank_id"], name: "index_game_prompts_on_blank_id"
    t.index ["game_id"], name: "index_game_prompts_on_game_id"
    t.index ["prompt_id"], name: "index_game_prompts_on_prompt_id"
  end

  create_table "games", force: :cascade do |t|
    t.integer "story_id", null: false
    t.integer "room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id"], name: "index_games_on_room_id"
    t.index ["story_id"], name: "index_games_on_story_id"
  end

  create_table "prompts", force: :cascade do |t|
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "tags"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "current_prompt_index", default: 0, null: false
    t.string "status", default: "WaitingRoom"
    t.index ["code"], name: "index_rooms_on_code", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "stories", force: :cascade do |t|
    t.string "original_text"
    t.string "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "title", null: false
    t.index ["title"], name: "index_stories_on_title", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "room_id", null: false
    t.index ["room_id", "name"], name: "index_users_on_room_id_and_name", unique: true
    t.index ["room_id"], name: "index_users_on_room_id"
  end

  create_table "votes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "answer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "room_id", null: false
    t.integer "prompt_id", null: false
    t.index ["answer_id"], name: "index_votes_on_answer_id"
    t.index ["prompt_id", "room_id", "user_id"], name: "index_votes_on_prompt_id_and_room_id_and_user_id", unique: true
    t.index ["prompt_id"], name: "index_votes_on_prompt_id"
    t.index ["room_id"], name: "index_votes_on_room_id"
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  add_foreign_key "answers", "prompts"
  add_foreign_key "answers", "rooms"
  add_foreign_key "answers", "users"
  add_foreign_key "blanks", "stories"
  add_foreign_key "game_prompts", "blanks"
  add_foreign_key "game_prompts", "prompts"
  add_foreign_key "game_prompts", "stories", column: "game_id"
  add_foreign_key "games", "rooms"
  add_foreign_key "games", "stories"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "rooms"
  add_foreign_key "votes", "answers"
  add_foreign_key "votes", "prompts"
  add_foreign_key "votes", "rooms"
  add_foreign_key "votes", "users"
end
