module GameSessions
  # Accepts client gameplay events, validates them, and records point deltas.
  class EventRecorder
    Result = Struct.new(:events, :server_score, :status, keyword_init: true)

    def initialize(game_session:, events:)
      @game_session = game_session
      @events = Array(events)
    end

    # Persists a batch of meaningful events. Frames are not accepted.
    #
    # Duplicate +event_key+ values are ignored so retries are safe.
    #
    # @return [Result]
    def call
      expire_if_needed!
      raise ArgumentError, "game is not running" unless @game_session.reload.running?

      recorded = []

      @game_session.with_lock do
        raise ArgumentError, "game is not running" unless @game_session.running?

        @events.each do |raw|
          recorded << persist_event(raw)
        end

        @game_session.update!(
          server_score: Scoring::Calculator.new(game_session: @game_session.reload).running_total,
          last_event_at: Time.current
        )
      end

      Result.new(events: recorded, server_score: @game_session.server_score, status: @game_session.status)
    end

    private

    def persist_event(raw)
      attrs = normalize(raw)
      existing = @game_session.game_events.find_by(event_key: attrs[:event_key])
      return existing if existing

      verdict = AntiCheat::EventValidator.new(game_session: @game_session, payload: attrs).call
      points = verdict.accepted ? Scoring::Catalog.new(game_session: @game_session).delta_for(attrs[:event_type]) : 0

      event = @game_session.game_events.create!(
        event_type: attrs[:event_type],
        event_key: attrs[:event_key],
        metadata: attrs[:metadata].presence || {},
        occurred_at: parse_time(attrs[:occurred_at]),
        accepted: verdict.accepted,
        rejection_reason: verdict.reason,
        points_delta: points
      )

      unless verdict.accepted
        @game_session.increment!(:rejected_event_count)
        AntiCheat::SessionReviewer.new(game_session: @game_session).review_after_rejection!
      end

      event
    end

    def expire_if_needed!
      config = GameConfiguration.current(@game_session.conference_event)
      return unless @game_session.started_at
      return if Time.current <= @game_session.started_at + config.duration_seconds.seconds + config.grace_seconds.seconds

      @game_session.update!(status: :expired, invalid_reason: "run exceeded allowed duration")
    end

    def parse_time(value)
      Time.zone.parse(value.to_s)
    rescue StandardError
      Time.current
    end

    def normalize(raw)
      hash = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h
      hash.with_indifferent_access
    end
  end
end
