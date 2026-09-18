module AntiCheat
  # Escalates a session to +invalid+ when the run looks fabricated.
  class SessionReviewer
    def initialize(game_session:)
      @game_session = game_session
      @config = GameConfiguration.current(game_session.conference_event)
    end

    # Called after a rejected event. A burst of rejections is treated as tampering.
    def review_after_rejection!
      return unless @game_session.rejected_event_count >= 12

      @game_session.update!(status: :invalid, invalid_reason: "too many rejected events")
    end

    # Decides whether a finished run may appear on the leaderboard.
    #
    # @return [Array(String, String)] status and optional reason
    def finish_status(breakdown:, client_score:)
      calculator = Scoring::Calculator.new(game_session: @game_session)

      if @game_session.rejected_event_count >= 12
        return [ "invalid", "too many rejected events" ]
      end

      if breakdown[:total] > calculator.theoretical_max
        return [ "invalid", "score exceeds theoretical maximum" ]
      end

      if client_score.present? && client_score.to_i > breakdown[:total] + 400
        return [ "invalid", "client score diverged from server score" ]
      end

      if @game_session.started_at && Time.current > @game_session.started_at + @config.duration_seconds.seconds + @config.grace_seconds.seconds + 30.seconds
        return [ "expired", "run exceeded allowed duration" ]
      end

      [ "completed", nil ]
    end
  end
end
