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

ActiveRecord::Schema[8.0].define(version: 2026_02_08_000003) do
  create_table "answers", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "game_prompt_id", null: false
    t.integer "game_id", null: false
    t.boolean "won"
    t.string "smoothed_text"
    t.index [ "game_id" ], name: "index_answers_on_game_id"
    t.index [ "game_prompt_id", "game_id", "user_id" ], name: "index_answers_on_game_prompt_id_and_game_id_and_user_id", unique: true
    t.index [ "game_prompt_id", "user_id" ], name: "index_game_prompts_on_game_prompt_id_and_room_id_and_user_id", unique: true
    t.index [ "game_prompt_id" ], name: "index_answers_on_game_prompt_id"
    t.index [ "user_id" ], name: "index_answers_on_user_id"
  end

  create_table "blanks", force: :cascade do |t|
    t.string "tags", null: false
    t.integer "story_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "story_id" ], name: "index_blanks_on_story_id"
  end

  create_table "discord_activity_tokens", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "token_digest" ], name: "index_discord_activity_tokens_on_token_digest", unique: true
    t.index [ "user_id" ], name: "index_discord_activity_tokens_on_user_id"
  end

  create_table "editor_email_changes", force: :cascade do |t|
    t.integer "editor_id", null: false
    t.string "new_email", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "editor_id" ], name: "index_editor_email_changes_on_editor_id"
    t.index [ "token_digest" ], name: "index_editor_email_changes_on_token_digest", unique: true
  end

  create_table "editor_invitations", force: :cascade do |t|
    t.string "email", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "accepted_at"
    t.integer "editor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "editor_id" ], name: "index_editor_invitations_on_editor_id"
    t.index [ "email" ], name: "index_editor_invitations_on_email"
    t.index [ "token_digest" ], name: "index_editor_invitations_on_token_digest", unique: true
  end

  create_table "editor_password_resets", force: :cascade do |t|
    t.integer "editor_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "editor_id" ], name: "index_editor_password_resets_on_editor_id"
    t.index [ "token_digest" ], name: "index_editor_password_resets_on_token_digest", unique: true
  end

  create_table "editor_sessions", force: :cascade do |t|
    t.integer "editor_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "editor_id" ], name: "index_editor_sessions_on_editor_id"
  end

  create_table "editors", force: :cascade do |t|
    t.string "username", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.index [ "email" ], name: "index_editors_on_email", unique: true
    t.index [ "username" ], name: "index_editors_on_username", unique: true
  end

  create_table "game_prompts", force: :cascade do |t|
    t.integer "game_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "prompt_id", null: false
    t.integer "blank_id", null: false
    t.integer "order", null: false
    t.index [ "blank_id" ], name: "index_game_prompts_on_blank_id"
    t.index [ "game_id", "prompt_id", "blank_id", "order" ], name: "index_game_prompts_on_game_prompt_blank_order", unique: true
    t.index [ "game_id" ], name: "index_game_prompts_on_game_id"
    t.index [ "prompt_id" ], name: "index_game_prompts_on_prompt_id"
  end

  create_table "games", force: :cascade do |t|
    t.integer "story_id", null: false
    t.integer "room_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "current_game_prompt_id"
    t.datetime "next_game_phase_time"
    t.string "answering_timer_job_id"
    t.string "voting_timer_job_id"
    t.index [ "current_game_prompt_id" ], name: "index_games_on_current_game_prompt_id"
    t.index [ "room_id" ], name: "index_games_on_room_id"
    t.index [ "story_id" ], name: "index_games_on_story_id"
  end

  create_table "genres", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "name" ], name: "index_genres_on_name", unique: true
  end

  create_table "prompts", force: :cascade do |t|
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "tags"
    t.integer "creator_id"
    t.index [ "creator_id" ], name: "index_prompts_on_creator_id"
  end

  create_table "rooms", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "WaitingRoom"
    t.integer "current_game_id"
    t.integer "time_to_answer_seconds", default: 180, null: false
    t.integer "time_to_vote_seconds", default: 120, null: false
    t.string "voting_style", default: "vote_once", null: false
    t.boolean "smooth_answers", default: false, null: false
    t.string "discord_instance_id"
    t.string "discord_channel_id"
    t.boolean "is_discord_activity", default: false
    t.index [ "code" ], name: "index_rooms_on_code", unique: true
    t.index [ "current_game_id" ], name: "index_rooms_on_current_game_id"
    t.index [ "discord_instance_id" ], name: "index_rooms_on_discord_instance_id", unique: true, where: "discord_instance_id IS NOT NULL"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "user_id" ], name: "index_sessions_on_user_id"
  end

  create_table "stories", force: :cascade do |t|
    t.string "original_text", default: "The original story goes here..."
    t.string "text", default: "Your story goes here..."
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "title", null: false
    t.boolean "published", default: false, null: false
    t.integer "author_id"
    t.index [ "author_id" ], name: "index_stories_on_author_id"
    t.index [ "published" ], name: "index_stories_on_published"
    t.index [ "title" ], name: "index_stories_on_title", unique: true
  end

  create_table "story_genres", force: :cascade do |t|
    t.integer "story_id", null: false
    t.integer "genre_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "genre_id" ], name: "index_story_genres_on_genre_id"
    t.index [ "story_id", "genre_id" ], name: "index_story_genres_on_story_id_and_genre_id", unique: true
    t.index [ "story_id" ], name: "index_story_genres_on_story_id"
  end

  create_table "story_prompts", force: :cascade do |t|
    t.integer "story_id", null: false
    t.integer "blank_id", null: false
    t.integer "prompt_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "blank_id" ], name: "index_story_prompts_on_blank_id"
    t.index [ "prompt_id" ], name: "index_story_prompts_on_prompt_id"
    t.index [ "story_id" ], name: "index_story_prompts_on_story_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "room_id", null: false
    t.string "role", default: "Player"
    t.boolean "is_active", default: true, null: false
    t.string "status", default: "Answering"
    t.string "avatar", null: false
    t.string "discord_id"
    t.string "discord_username"
    t.index [ "room_id", "avatar" ], name: "index_users_on_room_id_and_avatar", unique: true
    t.index [ "room_id", "discord_id" ], name: "index_users_on_room_id_and_discord_id", unique: true, where: "discord_id IS NOT NULL"
    t.index [ "room_id", "name" ], name: "index_users_on_room_id_and_name", unique: true
    t.index [ "room_id" ], name: "index_users_on_room_id"
  end

  create_table "votes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "answer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "game_id", null: false
    t.integer "game_prompt_id", null: false
    t.integer "rank"
    t.index [ "answer_id" ], name: "index_votes_on_answer_id"
    t.index [ "game_id" ], name: "index_votes_on_game_id"
    t.index [ "game_prompt_id", "rank" ], name: "index_votes_on_game_prompt_id_and_rank"
    t.index [ "game_prompt_id", "user_id", "answer_id" ], name: "idx_votes_prompt_user_answer_unique", unique: true
    t.index [ "game_prompt_id", "user_id", "rank" ], name: "idx_votes_prompt_user_rank_unique", unique: true, where: "rank IS NOT NULL"
    t.index [ "game_prompt_id" ], name: "index_votes_on_game_prompt_id"
    t.index [ "user_id" ], name: "index_votes_on_user_id"
  end

  add_foreign_key "answers", "game_prompts"
  add_foreign_key "answers", "games"
  add_foreign_key "answers", "users"
  add_foreign_key "blanks", "stories"
  add_foreign_key "discord_activity_tokens", "users"
  add_foreign_key "editor_email_changes", "editors"
  add_foreign_key "editor_invitations", "editors"
  add_foreign_key "editor_password_resets", "editors"
  add_foreign_key "editor_sessions", "editors"
  add_foreign_key "game_prompts", "blanks"
  add_foreign_key "game_prompts", "games"
  add_foreign_key "game_prompts", "prompts"
  add_foreign_key "games", "game_prompts", column: "current_game_prompt_id"
  add_foreign_key "games", "rooms"
  add_foreign_key "games", "stories"
  add_foreign_key "prompts", "editors", column: "creator_id"
  add_foreign_key "rooms", "games", column: "current_game_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "stories", "editors", column: "author_id"
  add_foreign_key "story_genres", "genres"
  add_foreign_key "story_genres", "stories"
  add_foreign_key "story_prompts", "blanks"
  add_foreign_key "story_prompts", "prompts"
  add_foreign_key "story_prompts", "stories"
  add_foreign_key "users", "rooms"
  add_foreign_key "votes", "answers"
  add_foreign_key "votes", "game_prompts"
  add_foreign_key "votes", "games"
  add_foreign_key "votes", "users"
end
