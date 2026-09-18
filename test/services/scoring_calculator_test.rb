require "test_helper"

class ScoringCalculatorTest < ActiveSupport::TestCase
  test "running total uses catalog values from configuration" do
    @config.update!(ruby_points: 10, bug_penalty: 7)
    session = start_session!
    GameSessions::EventRecorder.new(
      game_session: session,
      events: [
        { event_type: "ruby_collected", event_key: "r", occurred_at: Time.current.iso8601 },
        { event_type: "bug_hit", event_key: "b", occurred_at: Time.current.iso8601 }
      ]
    ).call
    total = Scoring::Calculator.new(game_session: session.reload).running_total
    assert_equal 3, total
  end
end
