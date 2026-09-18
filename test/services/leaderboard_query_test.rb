require "test_helper"

class LeaderboardQueryTest < ActiveSupport::TestCase
  test "orders by score then earliest finish" do
    first = publish_score("alpha", 500, 2.minutes.ago)
    _lower = publish_score("beta", 100, 1.minute.ago)
    tie = publish_score("gamma", 500, 1.minute.ago)

    names = Leaderboard::Query.new(conference_event: @event, scope: "conference").scores.map { |score| score.player.name }
    assert_equal [ "alpha", "gamma", "beta" ], names
    assert_equal 1, Leaderboard::Query.new(conference_event: @event).rank_for(first)
    assert_equal 2, Leaderboard::Query.new(conference_event: @event).rank_for(tie)
  end

  test "hides unpublished and can hide demo rows" do
    publish_score("live", 50, Time.current)
    demo_player = Player.create!(conference_event: @event, name: "demo", demo: true)
    demo_session = GameSessions::Creator.new(player: demo_player).call
    demo_session.update!(status: :completed)
    Score.create!(game_session: demo_session, player: demo_player, conference_event: @event, points: 999, demo: true, published: true)
    @config.update!(include_demo_on_leaderboard: false)

    names = Leaderboard::Query.new(conference_event: @event).scores.map { |score| score.player.name }
    assert_includes names, "live"
    assert_not_includes names, "demo"
  end

  test "today scope ignores yesterday" do
    publish_score("today", 10, Time.current)
    old = publish_score("old", 80, 2.days.ago)
    old.update_columns(created_at: 2.days.ago)
    names = Leaderboard::Query.new(conference_event: @event, scope: "today").scores.map { |score| score.player.name }
    assert_equal [ "today" ], names
  end

  private

  def publish_score(name, points, at)
    player = Player.create!(conference_event: @event, name: name)
    session = GameSessions::Creator.new(player: player).call
    session.update!(status: :completed, started_at: at, finished_at: at)
    Score.create!(game_session: session, player: player, conference_event: @event, points: points, published: true, created_at: at)
  end
end
