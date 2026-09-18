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

ActiveRecord::Schema[8.1].define(version: 2026_09_18_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "conference_events", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.integer "leaderboard_limit", default: 100, null: false
    t.string "location"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "starts_at"
    t.string "time_zone", default: "Asia/Kolkata", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_conference_events_on_active"
    t.index ["slug"], name: "index_conference_events_on_slug", unique: true
  end

  create_table "game_configurations", force: :cascade do |t|
    t.integer "boost_points", default: 100, null: false
    t.integer "bug_penalty", default: 50, null: false
    t.integer "completion_bonus", default: 500, null: false
    t.bigint "conference_event_id", null: false
    t.datetime "created_at", null: false
    t.boolean "difficulty_progression", default: true, null: false
    t.integer "duration_seconds", default: 90, null: false
    t.integer "event_min_interval_ms", default: 80, null: false
    t.integer "grace_seconds", default: 15, null: false
    t.boolean "include_demo_on_leaderboard", default: true, null: false
    t.integer "lives", default: 3, null: false
    t.integer "max_boost_events", default: 4, null: false
    t.integer "max_questions_per_run", default: 5, null: false
    t.integer "max_rails_events", default: 12, null: false
    t.integer "max_ruby_events", default: 45, null: false
    t.integer "max_special_events", default: 2, null: false
    t.integer "production_bug_penalty", default: 100, null: false
    t.integer "question_correct_points", default: 100, null: false
    t.integer "question_frequency_seconds", default: 20, null: false
    t.integer "question_wrong_penalty", default: 100, null: false
    t.integer "rails_points", default: 50, null: false
    t.integer "ruby_points", default: 25, null: false
    t.integer "special_ruby_points", default: 250, null: false
    t.integer "time_multiplier", default: 10, null: false
    t.datetime "updated_at", null: false
    t.index ["conference_event_id"], name: "index_game_configurations_on_conference_event_id"
  end

  create_table "game_events", force: :cascade do |t|
    t.boolean "accepted", default: true, null: false
    t.datetime "created_at", null: false
    t.string "event_key", null: false
    t.string "event_type", null: false
    t.bigint "game_session_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "occurred_at", null: false
    t.integer "points_delta", default: 0, null: false
    t.string "rejection_reason"
    t.datetime "updated_at", null: false
    t.index ["accepted"], name: "index_game_events_on_accepted"
    t.index ["game_session_id", "event_key"], name: "index_game_events_on_game_session_id_and_event_key", unique: true
    t.index ["game_session_id", "event_type"], name: "index_game_events_on_game_session_id_and_event_type"
    t.index ["game_session_id"], name: "index_game_events_on_game_session_id"
  end

  create_table "game_levels", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "name", null: false
    t.boolean "playable", default: false, null: false
    t.integer "sort_order", default: 1, null: false
    t.string "subtitle"
    t.jsonb "theme", default: {}, null: false
    t.datetime "updated_at", null: false
    t.integer "world_width", default: 6400, null: false
    t.index ["key"], name: "index_game_levels_on_key", unique: true
    t.index ["sort_order"], name: "index_game_levels_on_sort_order"
  end

  create_table "game_sessions", force: :cascade do |t|
    t.integer "client_reported_score"
    t.bigint "conference_event_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "device_info", default: {}, null: false
    t.integer "duration_seconds"
    t.datetime "expires_at"
    t.datetime "finished_at"
    t.bigint "game_level_id"
    t.string "invalid_reason"
    t.datetime "last_event_at"
    t.integer "lives_remaining"
    t.bigint "player_id", null: false
    t.integer "rejected_event_count", default: 0, null: false
    t.integer "server_score", default: 0, null: false
    t.datetime "started_at"
    t.string "status", default: "created", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["conference_event_id"], name: "index_game_sessions_on_conference_event_id"
    t.index ["game_level_id"], name: "index_game_sessions_on_game_level_id"
    t.index ["player_id", "created_at"], name: "index_game_sessions_on_player_id_and_created_at"
    t.index ["player_id"], name: "index_game_sessions_on_player_id"
    t.index ["status"], name: "index_game_sessions_on_status"
    t.index ["token"], name: "index_game_sessions_on_token", unique: true
  end

  create_table "players", force: :cascade do |t|
    t.string "company"
    t.bigint "conference_event_id", null: false
    t.datetime "created_at", null: false
    t.boolean "demo", default: false, null: false
    t.string "email"
    t.string "github_username"
    t.string "ip_address"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["conference_event_id"], name: "index_players_on_conference_event_id"
    t.index ["demo"], name: "index_players_on_demo"
    t.index ["github_username"], name: "index_players_on_github_username"
    t.index ["name"], name: "index_players_on_name"
  end

  create_table "question_attempts", force: :cascade do |t|
    t.datetime "answered_at"
    t.datetime "asked_at", null: false
    t.string "choice_key"
    t.boolean "correct"
    t.datetime "created_at", null: false
    t.string "difficulty"
    t.bigint "game_session_id", null: false
    t.integer "points_awarded", default: 0, null: false
    t.bigint "question_id", null: false
    t.datetime "updated_at", null: false
    t.index ["correct"], name: "index_question_attempts_on_correct"
    t.index ["game_session_id", "question_id"], name: "index_question_attempts_on_game_session_id_and_question_id", unique: true
    t.index ["game_session_id"], name: "index_question_attempts_on_game_session_id"
    t.index ["question_id"], name: "index_question_attempts_on_question_id"
  end

  create_table "questions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category", null: false
    t.jsonb "choices", default: [], null: false
    t.string "correct_choice_key", null: false
    t.datetime "created_at", null: false
    t.string "difficulty", default: "easy", null: false
    t.text "explanation"
    t.integer "points", default: 100, null: false
    t.text "prompt", null: false
    t.datetime "updated_at", null: false
    t.integer "wrong_points", default: 100, null: false
    t.index ["active"], name: "index_questions_on_active"
    t.index ["category"], name: "index_questions_on_category"
    t.index ["difficulty"], name: "index_questions_on_difficulty"
    t.index ["prompt"], name: "index_questions_on_prompt", unique: true
  end

  create_table "scores", force: :cascade do |t|
    t.integer "boosts_count", default: 0, null: false
    t.integer "bugs_hit", default: 0, null: false
    t.integer "completion_bonus", default: 0, null: false
    t.bigint "conference_event_id", null: false
    t.datetime "created_at", null: false
    t.boolean "demo", default: false, null: false
    t.bigint "game_session_id", null: false
    t.integer "gems_count", default: 0, null: false
    t.boolean "level_completed", default: false, null: false
    t.bigint "player_id", null: false
    t.integer "points", default: 0, null: false
    t.integer "production_bugs_hit", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.integer "questions_asked", default: 0, null: false
    t.integer "questions_correct", default: 0, null: false
    t.integer "specials_count", default: 0, null: false
    t.integer "time_bonus", default: 0, null: false
    t.integer "time_remaining", default: 0, null: false
    t.integer "tracks_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["conference_event_id", "published", "points"], name: "index_scores_for_leaderboard"
    t.index ["conference_event_id"], name: "index_scores_on_conference_event_id"
    t.index ["created_at", "published"], name: "index_scores_on_created_at_and_published"
    t.index ["demo"], name: "index_scores_on_demo"
    t.index ["game_session_id"], name: "index_scores_on_game_session_id", unique: true
    t.index ["player_id"], name: "index_scores_on_player_id"
  end

  add_foreign_key "game_configurations", "conference_events"
  add_foreign_key "game_events", "game_sessions"
  add_foreign_key "game_sessions", "conference_events"
  add_foreign_key "game_sessions", "game_levels"
  add_foreign_key "game_sessions", "players"
  add_foreign_key "players", "conference_events"
  add_foreign_key "question_attempts", "game_sessions"
  add_foreign_key "question_attempts", "questions"
  add_foreign_key "scores", "conference_events"
  add_foreign_key "scores", "game_sessions"
  add_foreign_key "scores", "players"
end
