# frozen_string_literal: true

event = ConferenceEvent.find_or_create_by!(slug: ENV.fetch("CONFERENCE_SLUG", "deccan-rails-conf")) do |record|
  record.name = "Deccan Rails Conf"
  record.location = "Pune"
  record.time_zone = "Asia/Kolkata"
  record.twitter_handle = "hideccanqueen"
  record.starts_at = Time.zone.parse("2026-09-18")
  record.ends_at = Time.zone.parse("2026-09-20").end_of_day
  record.active = true
end
event.update!(twitter_handle: "hideccanqueen") if event.twitter_handle.blank?

GameConfiguration.find_or_create_by!(conference_event: event)

levels = [
  [ "ruby_valley", "Ruby Valley", "Green hills, red gems, first deploy", 1, true ],
  [ "rails_city", "Rails City", "Coming after MVP", 2, false ],
  [ "database_dungeon", "Database Dungeon", "Coming after MVP", 3, false ],
  [ "production_mountain", "Production Mountain", "Coming after MVP", 4, false ],
  [ "production_boss", "The Production Boss", "Coming after MVP", 5, false ]
]

levels.each do |key, name, description, order, playable|
  GameLevel.find_or_create_by!(key: key) do |level|
    level.name = name
    level.description = description
    level.sort_order = order
    level.playable = playable
    level.active = true
  end
end

QUESTIONS = [
  [ "Which avoids an N+1 query?", "ActiveRecord", "easy", "B", "includes preloads the association in a bounded number of queries.", [
    [ "A", "User.all.each { |u| u.orders }" ],
    [ "B", "User.includes(:orders)" ],
    [ "C", "User.all.to_a" ],
    [ "D", "User.pluck(:orders)" ]
  ] ],
  [ "What does attr_accessor define?", "Ruby", "easy", "A", "It defines a getter and setter for an instance variable.", [
    [ "A", "Getter and setter methods" ],
    [ "B", "A class-level constant" ],
    [ "C", "A database column" ],
    [ "D", "A private method" ]
  ] ],
  [ "Which HTTP method does resources :posts map to #update?", "Rails", "easy", "C", "PATCH (and PUT) route to update.", [
    [ "A", "GET" ],
    [ "B", "POST" ],
    [ "C", "PATCH" ],
    [ "D", "DELETE" ]
  ] ],
  [ "Which SQL clause filters groups after aggregation?", "SQL", "medium", "C", "HAVING filters grouped rows; WHERE filters before grouping.", [
    [ "A", "WHERE" ],
    [ "B", "LIMIT" ],
    [ "C", "HAVING" ],
    [ "D", "ORDER BY" ]
  ] ],
  [ "Which index type is the PostgreSQL default?", "PostgreSQL", "easy", "B", "B-tree is the default and covers equality and range lookups.", [
    [ "A", "GIN" ],
    [ "B", "B-tree" ],
    [ "C", "GiST" ],
    [ "D", "BRIN" ]
  ] ],
  [ "What does Redis SET key value do if the key exists?", "Redis", "easy", "B", "SET overwrites the previous value.", [
    [ "A", "Appends the value" ],
    [ "B", "Overwrites the value" ],
    [ "C", "Raises an error" ],
    [ "D", "Creates a list" ]
  ] ],
  [ "Sidekiq jobs should be?", "Sidekiq", "medium", "A", "Idempotent jobs can be retried safely.", [
    [ "A", "Idempotent" ],
    [ "B", "Stored in PostgreSQL only" ],
    [ "C", "Always unique to one queue" ],
    [ "D", "Run inside the web request" ]
  ] ],
  [ "Which AWS service is object storage?", "AWS", "easy", "C", "S3 stores objects; EBS is block, RDS is relational.", [
    [ "A", "RDS" ],
    [ "B", "EBS" ],
    [ "C", "S3" ],
    [ "D", "ELB" ]
  ] ],
  [ "How do you avoid a Rails SQL injection?", "Security", "easy", "B", "Use bound parameters / hash conditions, never interpolate user input.", [
    [ "A", 'User.where("name = #{params[:name]}")' ],
    [ "B", "User.where(name: params[:name])" ],
    [ "C", 'User.find_by_sql("name = #{params[:name]}")' ],
    [ "D", "User.connection.execute(params[:sql])" ]
  ] ],
  [ "Which call is typically fastest for a single column list?", "Performance", "medium", "C", "pluck selects only that column and returns raw values.", [
    [ "A", "User.all.map(&:id)" ],
    [ "B", "User.select(:id).to_a.map(&:id)" ],
    [ "C", "User.pluck(:id)" ],
    [ "D", "User.all.to_json" ]
  ] ],
  [ "A background job that must survive a deploy should be?", "SystemDesign", "medium", "B", "Durable queues keep jobs across process restarts.", [
    [ "A", "Kept in memory in Puma" ],
    [ "B", "Persisted on Redis or the database" ],
    [ "C", "Spawned with Thread.new only" ],
    [ "D", "Stored in the browser" ]
  ] ],
  [ "What does freeze do to a Ruby string?", "Ruby", "easy", "A", "Frozen objects raise if you try to mutate them.", [
    [ "A", "Makes it immutable" ],
    [ "B", "Deletes it" ],
    [ "C", "Moves it to Redis" ],
    [ "D", "Makes it a symbol" ]
  ] ],
  [ "Which callback runs after a record is committed?", "Rails", "medium", "C", "after_commit is safe for side effects that must not roll back.", [
    [ "A", "before_validation" ],
    [ "B", "around_save" ],
    [ "C", "after_commit" ],
    [ "D", "after_initialize" ]
  ] ],
  [ "What is an EXPLAIN ANALYZE used for?", "PostgreSQL", "medium", "B", "It executes the query and reports the real plan and timings.", [
    [ "A", "Rewriting the query automatically" ],
    [ "B", "Showing the executed query plan" ],
    [ "C", "Creating an index" ],
    [ "D", "Vacuuming a table" ]
  ] ],
  [ "counter_cache on belongs_to helps you avoid?", "ActiveRecord", "medium", "A", "It stores the association size so you do not COUNT every time.", [
    [ "A", "Counting children on every read" ],
    [ "B", "Using foreign keys" ],
    [ "C", "Using transactions" ],
    [ "D", "Using JSONB" ]
  ] ],
  [ "SELECT * FROM users FOR UPDATE is used to?", "SQL", "hard", "B", "It row-locks the selected rows until commit.", [
    [ "A", "Skip indexes" ],
    [ "B", "Lock selected rows" ],
    [ "C", "Drop the table" ],
    [ "D", "Create a materialized view" ]
  ] ],
  [ "Redis MULTI / EXEC gives you?", "Redis", "medium", "A", "A transaction of queued commands.", [
    [ "A", "A transaction block" ],
    [ "B", "Pub/sub" ],
    [ "C", "Cluster slots" ],
    [ "D", "A Lua compiler" ]
  ] ],
  [ "A Sidekiq retry that keeps failing ends up in?", "Sidekiq", "easy", "C", "The Dead set holds jobs that exhausted retries.", [
    [ "A", "Postgres" ],
    [ "B", "the web session" ],
    [ "C", "the Dead set" ],
    [ "D", "S3" ]
  ] ],
  [ "Which header helps prevent clickjacking?", "Security", "medium", "A", "X-Frame-Options (or CSP frame-ancestors) controls embedding.", [
    [ "A", "X-Frame-Options" ],
    [ "B", "ETag" ],
    [ "C", "Accept-Language" ],
    [ "D", "If-None-Match" ]
  ] ],
  [ "An RDS read replica is typically used to?", "AWS", "medium", "B", "Replicas scale reads; writes still go to the primary.", [
    [ "A", "Accept writes for the primary" ],
    [ "B", "Offload read traffic" ],
    [ "C", "Replace S3" ],
    [ "D", "Terminate TLS for Puma" ]
  ] ],
  [ "fragment caching in Rails stores?", "Performance", "easy", "C", "Rendered view fragments, keyed by cache keys.", [
    [ "A", "SQL query plans only" ],
    [ "B", "The entire database" ],
    [ "C", "Rendered HTML fragments" ],
    [ "D", "Puma threads" ]
  ] ],
  [ "A circuit breaker in a service design protects you from?", "SystemDesign", "hard", "A", "It stops calling a failing dependency so the rest of the app can survive.", [
    [ "A", "Cascading failures" ],
    [ "B", "Missing indexes" ],
    [ "C", "Slow CSS" ],
    [ "D", "Expired cookies" ]
  ] ]
].freeze

QUESTIONS.each do |prompt, category, difficulty, correct, explanation, answers|
  question = Question.find_or_initialize_by(prompt: prompt)
  question.assign_attributes(
    category: category,
    difficulty: difficulty,
    correct_choice_key: correct,
    explanation: explanation,
    active: true,
    choices: answers.map { |key, text| { "key" => key, "text" => text } }
  )
  question.save!
end

# Development/demo leaderboard rows — clearly marked demo: true. Safe to disable in admin.
if Player.demo.none?
  demo_board = [
    [ "ruby_ninja", "ruby_ninja", "Hydra", 8750 ],
    [ "rails_rockstar", "rails_rockstar", "Deccan Labs", 8420 ],
    [ "vishal", "vishal", "Saeloun", 8100 ],
    [ "code_monkey", "code_monkey", "NilClass Inc", 7950 ],
    [ "rails_guru", "rails_guru", "Active Record Fanclub", 7620 ]
  ]

  demo_board.each_with_index do |(name, github, company, points), index|
    player = Player.create!(
      conference_event: event,
      name: name,
      github_username: github,
      company: company,
      demo: true
    )
    session = GameSessions::Creator.new(player: player).call
    session.update!(
      status: :completed,
      started_at: 2.hours.ago,
      finished_at: 2.hours.ago + 70.seconds,
      server_score: points
    )
    Score.create!(
      game_session: session,
      player: player,
      conference_event: event,
      points: points,
      gems_count: 20 + index,
      tracks_count: 4,
      questions_correct: 4,
      questions_asked: 5,
      time_remaining: 20 - index,
      time_bonus: (20 - index) * 10,
      completion_bonus: 500,
      level_completed: true,
      demo: true,
      published: true
    )
  end
end

puts "Seeded #{Question.count} questions, #{Player.demo.count} demo players for #{event.name}."
