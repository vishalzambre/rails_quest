module AntiCheat
  # Lightweight checks for a single gameplay event. Impossible frequencies or
  # unknown types are rejected; the session is marked invalid only after a pattern of abuse.
  class EventValidator
    Verdict = Struct.new(:accepted, :reason, keyword_init: true)

    LIMITS = {
      "ruby_collected" => :max_ruby_events,
      "rails_collected" => :max_rails_events,
      "boost_collected" => :max_boost_events,
      "special_collected" => :max_special_events
    }.freeze

    def initialize(game_session:, payload:)
      @game_session = game_session
      @payload = payload.to_h.with_indifferent_access
      @config = GameConfiguration.current(game_session.conference_event)
    end

    # @return [Verdict]
    def call
      return reject("unknown event type") unless GameEvent::TYPES.include?(@payload[:event_type].to_s)
      return reject("missing event key") if @payload[:event_key].blank?
      return reject("game is not running") unless @game_session.running?
      return reject("event outside the run window") unless within_window?
      return reject("events arriving too quickly") if too_frequent?
      return reject("too many events of this type") if over_type_limit?

      Verdict.new(accepted: true, reason: nil)
    end

    private

    def reject(reason)
      Verdict.new(accepted: false, reason: reason)
    end

    def within_window?
      return false unless @game_session.started_at

      occurred = begin
        Time.zone.parse(@payload[:occurred_at].to_s)
      rescue StandardError
        Time.current
      end

      earliest = @game_session.started_at - 2.seconds
      latest = @game_session.started_at + @config.duration_seconds.seconds + @config.grace_seconds.seconds
      occurred.between?(earliest, latest)
    end

    def too_frequent?
      return false unless collectable?

      last = @game_session.game_events.accepted.of_type(@payload[:event_type]).order(:occurred_at).last
      return false unless last

      occurred = parse_time(@payload[:occurred_at])
      (occurred - last.occurred_at).abs < (@config.event_min_interval_ms / 1000.0)
    end

    def parse_time(value)
      Time.zone.parse(value.to_s)
    rescue StandardError
      Time.current
    end

    def collectable?
      LIMITS.key?(@payload[:event_type].to_s)
    end

    def over_type_limit?
      field = LIMITS[@payload[:event_type].to_s]
      return false unless field

      @game_session.game_events.accepted.of_type(@payload[:event_type]).count >= @config.public_send(field)
    end
  end
end
