require "test_helper"

class ResultsControllerTest < ActionDispatch::IntegrationTest
  test "results page shares the score through an external script" do
    session = start_session!
    GameSessions::Finisher.new(game_session: session, outcome: "completed").call

    get result_url(session.token)

    assert_response :success
    assert_select "[data-share][data-text*='I scored']"
    assert_select "script", text: /navigator.share/, count: 0
    assert_includes response.body, "results.ts"
  end

  test "results page links to X when the conference has a handle" do
    @event.update!(twitter_handle: "hideccanqueen")
    session = start_session!
    GameSessions::Finisher.new(game_session: session, outcome: "completed").call

    get result_url(session.token)

    assert_select "a[data-twitter-share][href*='twitter.com/intent/tweet']"
    assert_select "a[data-twitter-share][href*='hideccanqueen']"
  end

  test "results page hides X share when the conference has no handle" do
    @event.update!(twitter_handle: nil)
    session = start_session!
    GameSessions::Finisher.new(game_session: session, outcome: "completed").call

    get result_url(session.token)

    assert_select "a[data-twitter-share]", count: 0
  end
end
