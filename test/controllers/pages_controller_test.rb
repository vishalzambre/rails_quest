require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "landing page renders the board without play now" do
    get root_url
    assert_response :success
    assert_select "h1", /RAILS/
    assert_select "a", text: "PLAY NOW", count: 0
    assert_select "a", text: "LEADERBOARD"
  end

  test "event cabinet link shows play now for that conference" do
    get event_root_url(@event.slug)
    assert_response :success
    assert_select "a", text: "PLAY NOW"
    assert_select ".conf-mark", text: /#{Regexp.escape(@event.name)}/
  end

  test "unscoped registration is closed" do
    get register_url
    assert_redirected_to root_path
  end

  test "event registration creates a player on that conference" do
    assert_difference -> { Player.count } => 1, -> { GameSession.count } => 1 do
      post event_register_url(@event.slug), params: { player: { name: "Mobile Dev", github_username: "dev" } }
    end
    assert_redirected_to event_instructions_path(@event.slug)
    assert_equal @event.id, Player.find_by!(name: "Mobile Dev").conference_event_id
  end

  test "leaderboard lists published scores without emails" do
    session = start_session!
    GameSessions::Finisher.new(game_session: session, outcome: "completed").call
    @player.update!(email: "secret@example.com")
    get leaderboard_url
    assert_response :success
    assert_select "body", text: /secret@example.com/, count: 0
    assert_select "[data-leaderboard][data-scope=live]"
  end

  test "live and today leaderboard scopes render" do
    get live_leaderboard_url
    assert_response :success
    get today_leaderboard_url
    assert_response :success
  end
end
