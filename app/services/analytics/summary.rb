module Analytics
  # Aggregates conference play statistics for the admin dashboard.
  class Summary
    def initialize(conference_event:)
      @event = conference_event
      @sessions = GameSession.where(conference_event: @event)
    end

    # @return [Hash]
    def call
      completed = @sessions.completed
      scores = Score.for_event(@event).published
      attempts = QuestionAttempt.joins(:game_session).where(game_sessions: { conference_event_id: @event.id }).answered

      {
        players_started: @sessions.where.not(started_at: nil).select(:player_id).distinct.count,
        games_completed: completed.count,
        games_abandoned: @sessions.where(status: %w[created running expired]).where.not(started_at: nil).count,
        invalid_games: @sessions.where(status: "invalid").count,
        average_score: scores.average(:points).to_f.round,
        highest_score: scores.maximum(:points).to_i,
        average_duration: average_duration(completed),
        questions_answered: attempts.count,
        question_accuracy: accuracy(attempts),
        most_missed_questions: most_missed,
        devices: device_breakdown
      }
    end

    private

    def average_duration(completed)
      durations = completed.filter_map { |session| session.finished_at && session.started_at && (session.finished_at - session.started_at) }
      return 0 if durations.empty?

      (durations.sum / durations.size).round
    end

    def accuracy(attempts)
      return 0 if attempts.none?

      ((attempts.correct.count.to_f / attempts.count) * 100).round
    end

    def most_missed
      Question.joins(:question_attempts)
        .where(question_attempts: { correct: false })
        .group("questions.id")
        .order("COUNT(question_attempts.id) DESC")
        .limit(5)
        .pluck(:prompt, Arel.sql("COUNT(question_attempts.id)"))
        .map { |prompt, count| { prompt: prompt, misses: count } }
    end

    def device_breakdown
      user_agents = Player.where(conference_event: @event).where.not(user_agent: [ nil, "" ]).pluck(:user_agent)
      {
        ios: user_agents.count { |agent| agent.match?(/iPhone|iPad/i) },
        android: user_agents.count { |agent| agent.match?(/Android/i) },
        desktop: user_agents.count { |agent| agent.match?(/Macintosh|Windows|Linux/i) && !agent.match?(/Mobile/i) }
      }
    end
  end
end
