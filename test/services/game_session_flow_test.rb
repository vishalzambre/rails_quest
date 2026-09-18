require "test_helper"

class GameSessionFlowTest < ActiveSupport::TestCase
  test "creates a session with a secure token" do
    session = GameSessions::Creator.new(player: @player).call
    assert session.created?
    assert session.token.present?
    assert_equal @config.duration_seconds, session.duration_seconds
    assert_equal @config.lives, session.lives_remaining
  end

  test "starts a session once" do
    session = start_session!
    assert session.running?
    assert session.started_at.present?
    assert_equal 1, session.game_events.of_type("game_started").count
  end

  test "records collect events and calculates server score" do
    session = start_session!
    GameSessions::EventRecorder.new(
      game_session: session,
      events: [
        { event_type: "ruby_collected", event_key: "g1", occurred_at: Time.current.iso8601 },
        { event_type: "rails_collected", event_key: "t1", occurred_at: Time.current.iso8601 }
      ]
    ).call

    session.reload
    assert_equal @config.ruby_points + @config.rails_points, session.server_score
  end

  test "duplicate event keys are ignored" do
    session = start_session!
    payload = [ { event_type: "ruby_collected", event_key: "same", occurred_at: Time.current.iso8601 } ]
    GameSessions::EventRecorder.new(game_session: session, events: payload).call
    GameSessions::EventRecorder.new(game_session: session.reload, events: payload).call
    assert_equal 1, session.game_events.of_type("ruby_collected").count
  end

  test "rejects unknown event types" do
    session = start_session!
    GameSessions::EventRecorder.new(
      game_session: session,
      events: [ { event_type: "score_hack", event_key: "x", occurred_at: Time.current.iso8601 } ]
    ).call
    event = session.game_events.last
    assert_not event.accepted?
  end

  test "finish calculates score and publishes a leaderboard row" do
    session = start_session!
    GameSessions::EventRecorder.new(
      game_session: session,
      events: [ { event_type: "ruby_collected", event_key: "g2", occurred_at: Time.current.iso8601 } ]
    ).call
    score = GameSessions::Finisher.new(game_session: session.reload, outcome: "finished").call
    assert session.reload.completed?
    assert_equal @config.ruby_points, score.points
    assert score.published?
  end

  test "duplicate finish returns the same score" do
    session = start_session!
    first = GameSessions::Finisher.new(game_session: session, outcome: "finished").call
    second = GameSessions::Finisher.new(game_session: session.reload, outcome: "finished").call
    assert_equal first.id, second.id
    assert_equal 1, Score.where(game_session: session).count
  end

  test "completion adds bonus and time bonus" do
    session = start_session!
    score = GameSessions::Finisher.new(game_session: session, outcome: "completed").call
    assert score.level_completed?
    assert_equal @config.completion_bonus, score.completion_bonus
    assert score.time_bonus >= 0
    assert_operator score.points, :>=, @config.completion_bonus
  end
end
