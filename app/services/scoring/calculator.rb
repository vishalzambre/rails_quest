module Scoring
  # Authoritative score for a session. The Phaser HUD is a preview only.
  class Calculator
    def initialize(game_session:)
      @game_session = game_session
      @config = GameConfiguration.current(game_session.conference_event)
    end

    # Sum of accepted collect/hit events and graded questions, used while the run is live.
    #
    # @return [Integer]
    def running_total
      event_points + question_points
    end

    # Full end-of-run breakdown including time and completion bonuses.
    #
    # @param completed [Boolean] whether the player reached the deploy checkpoint
    # @param now [Time]
    # @return [Hash]
    def breakdown(completed: false, now: Time.current)
      gems = count("ruby_collected")
      tracks = count("rails_collected")
      boosts = count("boost_collected")
      specials = count("special_collected")
      bugs = count("bug_hit")
      production_bugs = count("production_bug_hit")
      asked = @game_session.question_attempts.count
      correct = @game_session.question_attempts.correct.count
      remaining = completed ? @game_session.remaining_seconds(at: now) : 0
      time_bonus = remaining * @config.time_multiplier
      completion_bonus = completed ? @config.completion_bonus : 0

      collect_points = (gems * @config.ruby_points) +
        (tracks * @config.rails_points) +
        (boosts * @config.boost_points) +
        (specials * @config.special_ruby_points)
      penalty_points = (bugs * @config.bug_penalty) + (production_bugs * @config.production_bug_penalty)
      total = collect_points - penalty_points + question_points + completion_bonus + time_bonus

      {
        gems_count: gems,
        tracks_count: tracks,
        boosts_count: boosts,
        specials_count: specials,
        bugs_hit: bugs,
        production_bugs_hit: production_bugs,
        questions_asked: asked,
        questions_correct: correct,
        time_remaining: remaining,
        time_bonus: time_bonus,
        completion_bonus: completion_bonus,
        total: total
      }
    end

    # Upper bound used by anti-cheat to reject impossible published scores.
    #
    # @return [Integer]
    def theoretical_max
      @config.max_ruby_events * @config.ruby_points +
        @config.max_rails_events * @config.rails_points +
        @config.max_boost_events * @config.boost_points +
        @config.max_special_events * @config.special_ruby_points +
        (@config.max_questions_per_run * @config.question_correct_points) +
        @config.completion_bonus +
        (@config.duration_seconds * @config.time_multiplier)
    end

    private

    def event_points
      @game_session.game_events.accepted.sum(:points_delta)
    end

    def question_points
      @game_session.question_attempts.answered.sum(:points_awarded)
    end

    def count(event_type)
      @game_session.game_events.accepted.of_type(event_type).count
    end
  end
end
