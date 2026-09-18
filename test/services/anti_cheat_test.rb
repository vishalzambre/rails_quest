require "test_helper"

class AntiCheatTest < ActiveSupport::TestCase
  test "marks impossible scores invalid" do
    session = start_session!
    calculator = Scoring::Calculator.new(game_session: session)
    breakdown = calculator.breakdown(completed: true)
    breakdown[:total] = calculator.theoretical_max + 10_000
    status, reason = AntiCheat::SessionReviewer.new(game_session: session).finish_status(breakdown: breakdown, client_score: nil)
    assert_equal "invalid", status
    assert_match(/theoretical/, reason)
  end

  test "expired sessions cannot keep running events after the window" do
    session = start_session!
    session.update!(started_at: 10.minutes.ago, duration_seconds: 90)
    result = GameSessions::EventRecorder.new(
      game_session: session,
      events: [ { event_type: "ruby_collected", event_key: "late", occurred_at: Time.current.iso8601 } ]
    )
    assert_raises(ArgumentError) { result.call }
    assert_equal "expired", session.reload.status
  end

  test "caps collectible counts" do
    session = start_session!
    @config.update!(max_ruby_events: 1)
    GameSessions::EventRecorder.new(
      game_session: session,
      events: [
        { event_type: "ruby_collected", event_key: "a", occurred_at: Time.current.iso8601 },
        { event_type: "ruby_collected", event_key: "b", occurred_at: Time.current.iso8601 }
      ]
    ).call
    accepted = session.game_events.accepted.of_type("ruby_collected").count
    assert_equal 1, accepted
  end
end
