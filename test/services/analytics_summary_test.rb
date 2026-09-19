require "test_helper"

class AnalyticsSummaryTest < ActiveSupport::TestCase
  test "dashboard summary counts completed runs without enum scopes" do
    session = start_session!
    GameSessions::Finisher.new(game_session: session, outcome: "completed").call

    summary = Analytics::Summary.new(conference_event: @event).call

    assert_equal 1, summary[:games_completed]
    assert summary[:highest_score] >= 0
  end
end
