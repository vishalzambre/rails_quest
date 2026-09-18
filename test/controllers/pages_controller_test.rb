require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "landing page renders" do
    get root_url
    assert_response :success
    assert_select "h1", /RAILS/
  end

  test "registration creates a player and session" do
    assert_difference -> { Player.count } => 1, -> { GameSession.count } => 1 do
      post register_url, params: { player: { name: "Mobile Dev", github_username: "dev" } }
    end
    assert_redirected_to instructions_path
  end

  test "leaderboard lists published scores without emails" do
    session = start_session!
    GameSessions::Finisher.new(game_session: session, outcome: "completed").call
    @player.update!(email: "secret@example.com")
    get leaderboard_url
    assert_response :success
    assert_select "body", text: /secret@example.com/, count: 0
  end
end
