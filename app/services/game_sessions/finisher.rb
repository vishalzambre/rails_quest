module GameSessions
  # Closes a run, calculates the authoritative score, and publishes it when valid.
  class Finisher
    class AlreadyFinished < StandardError; end
    class NotRunning < StandardError; end

    def initialize(game_session:, client_score: nil, outcome: "finished")
      @game_session = game_session
      @client_score = client_score
      @outcome = outcome.to_s
    end

    # Completes the session exactly once. Subsequent calls return the existing score.
    #
    # @return [Score]
    def call
      return @game_session.score if @game_session.score.present?
      raise AlreadyFinished if @game_session.completed? && @game_session.score.present?
      raise NotRunning, "finish is only allowed for a running game" unless @game_session.running? || @game_session.expired?

      @game_session.with_lock do
        return @game_session.score if @game_session.score.present?

        calculator = Scoring::Calculator.new(game_session: @game_session)
        breakdown = calculator.breakdown(completed: completed?, now: Time.current)
        status, reason = AntiCheat::SessionReviewer.new(game_session: @game_session).finish_status(breakdown: breakdown, client_score: @client_score)

        @game_session.update!(
          status: status,
          finished_at: Time.current,
          server_score: breakdown[:total],
          client_reported_score: @client_score,
          invalid_reason: reason
        )

        record_finish_event!(breakdown)

        Score.create!(
          game_session: @game_session,
          player: @game_session.player,
          conference_event: @game_session.conference_event,
          points: breakdown[:total],
          gems_count: breakdown[:gems_count],
          tracks_count: breakdown[:tracks_count],
          boosts_count: breakdown[:boosts_count],
          specials_count: breakdown[:specials_count],
          bugs_hit: breakdown[:bugs_hit],
          production_bugs_hit: breakdown[:production_bugs_hit],
          questions_correct: breakdown[:questions_correct],
          questions_asked: breakdown[:questions_asked],
          time_remaining: breakdown[:time_remaining],
          time_bonus: breakdown[:time_bonus],
          completion_bonus: breakdown[:completion_bonus],
          level_completed: completed?,
          demo: @game_session.player.demo?,
          published: status == "completed"
        )
      end

      score = @game_session.score
      Broadcasts::Leaderboard.new(score: score).call if score.published?
      score
    end

    private

    def completed?
      @outcome == "completed" || @game_session.game_events.accepted.of_type("level_completed").exists?
    end

    def record_finish_event!(breakdown)
      @game_session.game_events.find_or_create_by!(event_key: "finish-#{@game_session.token}") do |event|
        event.event_type = "game_finished"
        event.occurred_at = Time.current
        event.accepted = true
        event.metadata = { outcome: @outcome, total: breakdown[:total] }
      end
    end
  end
end
