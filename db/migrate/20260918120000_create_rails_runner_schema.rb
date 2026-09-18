class CreateRailsRunnerSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :conference_events do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :location
      t.string :time_zone, default: "Asia/Kolkata", null: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :active, default: true, null: false
      t.integer :leaderboard_limit, default: 100, null: false
      t.timestamps
    end
    add_index :conference_events, :slug, unique: true
    add_index :conference_events, :active

    create_table :game_configurations do |t|
      t.references :conference_event, null: false, foreign_key: true
      t.integer :duration_seconds, default: 90, null: false
      t.integer :lives, default: 3, null: false
      t.integer :question_frequency_seconds, default: 20, null: false
      t.integer :max_questions_per_run, default: 5, null: false
      t.boolean :difficulty_progression, default: true, null: false
      t.integer :ruby_points, default: 25, null: false
      t.integer :rails_points, default: 50, null: false
      t.integer :boost_points, default: 100, null: false
      t.integer :special_ruby_points, default: 250, null: false
      t.integer :bug_penalty, default: 50, null: false
      t.integer :production_bug_penalty, default: 100, null: false
      t.integer :question_correct_points, default: 100, null: false
      t.integer :question_wrong_penalty, default: 100, null: false
      t.integer :completion_bonus, default: 500, null: false
      t.integer :time_multiplier, default: 10, null: false
      t.integer :grace_seconds, default: 15, null: false
      t.integer :event_min_interval_ms, default: 80, null: false
      t.integer :max_ruby_events, default: 45, null: false
      t.integer :max_rails_events, default: 12, null: false
      t.integer :max_boost_events, default: 4, null: false
      t.integer :max_special_events, default: 2, null: false
      t.boolean :include_demo_on_leaderboard, default: true, null: false
      t.timestamps
    end

    create_table :game_levels do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.string :subtitle
      t.text :description
      t.integer :sort_order, default: 1, null: false
      t.boolean :active, default: true, null: false
      t.boolean :playable, default: false, null: false
      t.integer :world_width, default: 6400, null: false
      t.jsonb :theme, default: {}, null: false
      t.timestamps
    end
    add_index :game_levels, :key, unique: true
    add_index :game_levels, :sort_order

    create_table :players do |t|
      t.references :conference_event, null: false, foreign_key: true
      t.string :name, null: false
      t.string :github_username
      t.string :email
      t.string :company
      t.boolean :demo, default: false, null: false
      t.string :user_agent
      t.string :ip_address
      t.timestamps
    end
    add_index :players, :name
    add_index :players, :github_username
    add_index :players, :demo

    create_table :game_sessions do |t|
      t.references :player, null: false, foreign_key: true
      t.references :conference_event, null: false, foreign_key: true
      t.references :game_level, foreign_key: true
      t.string :token, null: false
      t.string :status, default: "created", null: false
      t.datetime :started_at
      t.datetime :finished_at
      t.datetime :expires_at
      t.datetime :last_event_at
      t.integer :lives_remaining
      t.integer :duration_seconds
      t.integer :client_reported_score
      t.integer :server_score, default: 0, null: false
      t.string :invalid_reason
      t.jsonb :device_info, default: {}, null: false
      t.integer :rejected_event_count, default: 0, null: false
      t.timestamps
    end
    add_index :game_sessions, :token, unique: true
    add_index :game_sessions, :status
    add_index :game_sessions, [ :player_id, :created_at ]

    create_table :questions do |t|
      t.text :prompt, null: false
      t.string :category, null: false
      t.string :difficulty, default: "easy", null: false
      t.jsonb :choices, default: [], null: false
      t.string :correct_choice_key, null: false
      t.integer :points, default: 100, null: false
      t.integer :wrong_points, default: 100, null: false
      t.boolean :active, default: true, null: false
      t.text :explanation
      t.timestamps
    end
    add_index :questions, :category
    add_index :questions, :difficulty
    add_index :questions, :active
    add_index :questions, :prompt, unique: true

    create_table :question_attempts do |t|
      t.references :game_session, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.string :choice_key
      t.boolean :correct
      t.integer :points_awarded, default: 0, null: false
      t.string :difficulty
      t.datetime :asked_at, null: false
      t.datetime :answered_at
      t.timestamps
    end
    add_index :question_attempts, [ :game_session_id, :question_id ], unique: true
    add_index :question_attempts, :correct

    create_table :game_events do |t|
      t.references :game_session, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :event_key, null: false
      t.jsonb :metadata, default: {}, null: false
      t.datetime :occurred_at, null: false
      t.boolean :accepted, default: true, null: false
      t.string :rejection_reason
      t.integer :points_delta, default: 0, null: false
      t.timestamps
    end
    add_index :game_events, [ :game_session_id, :event_key ], unique: true
    add_index :game_events, [ :game_session_id, :event_type ]
    add_index :game_events, :accepted

    create_table :scores do |t|
      t.references :game_session, null: false, foreign_key: true, index: { unique: true }
      t.references :player, null: false, foreign_key: true
      t.references :conference_event, null: false, foreign_key: true
      t.integer :points, default: 0, null: false
      t.integer :gems_count, default: 0, null: false
      t.integer :tracks_count, default: 0, null: false
      t.integer :boosts_count, default: 0, null: false
      t.integer :specials_count, default: 0, null: false
      t.integer :bugs_hit, default: 0, null: false
      t.integer :production_bugs_hit, default: 0, null: false
      t.integer :questions_correct, default: 0, null: false
      t.integer :questions_asked, default: 0, null: false
      t.integer :time_remaining, default: 0, null: false
      t.integer :time_bonus, default: 0, null: false
      t.integer :completion_bonus, default: 0, null: false
      t.boolean :level_completed, default: false, null: false
      t.boolean :demo, default: false, null: false
      t.boolean :published, default: true, null: false
      t.timestamps
    end
    add_index :scores, [ :conference_event_id, :published, :points ], name: "index_scores_for_leaderboard"
    add_index :scores, [ :created_at, :published ]
    add_index :scores, :demo
  end
end
