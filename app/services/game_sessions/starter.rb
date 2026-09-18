module GameSessions
  # Moves a session from +created+ into +running+ and records the authoritative start timestamp.
  class Starter
    class AlreadyStarted < StandardError; end
    class NotStartable < StandardError; end

    def initialize(game_session:)
      @game_session = game_session
    end

    # Marks the session running, stamps +started_at+, and writes a +game_started+ event.
    #
    # @return [GameSession]
    def call
      raise AlreadyStarted, "this run already started" if @game_session.running? && @game_session.started_at.present?
      raise NotStartable, "this run cannot be started" unless @game_session.created? || @game_session.running?

      now = Time.current
      config = GameConfiguration.current(@game_session.conference_event)

      @game_session.with_lock do
        next @game_session if @game_session.running? && @game_session.started_at.present?

        @game_session.update!(
          status: :running,
          started_at: now,
          last_event_at: now,
          expires_at: now + config.duration_seconds.seconds + config.grace_seconds.seconds,
          lives_remaining: @game_session.lives_remaining.presence || config.lives,
          duration_seconds: @game_session.duration_seconds.presence || config.duration_seconds
        )

        @game_session.game_events.create!(
          event_type: "game_started",
          event_key: "start-#{@game_session.token}",
          occurred_at: now,
          accepted: true,
          metadata: { level: @game_session.game_level&.key }
        )
      end

      @game_session
    end
  end
end
