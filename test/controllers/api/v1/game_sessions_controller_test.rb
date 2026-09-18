require "test_helper"

class Api::V1::GameSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @session = start_session!
  end

  test "starts, records events, answers a question, and finishes" do
    question = create_question!

    post start_api_v1_game_session_url(@session), headers: token_headers(@session)
    assert_response :success

    post events_api_v1_game_session_url(@session),
         params: { events: [ { event_type: "ruby_collected", event_key: "api-1", occurred_at: Time.current.iso8601 } ] },
         as: :json,
         headers: token_headers(@session)
    assert_response :success
    assert_equal 25, response.parsed_body["server_score"]

    post challenge_api_v1_game_session_url(@session), headers: token_headers(@session), as: :json
    assert_response :success
    refute response.parsed_body.key?("correct_choice_key")

    post answer_api_v1_game_session_question_url(@session, question),
         params: { choice_key: "B" },
         as: :json,
         headers: token_headers(@session)
    assert_response :success
    assert_equal true, response.parsed_body["correct"]

    post finish_api_v1_game_session_url(@session),
         params: { outcome: "completed", client_score: 9_999_999 },
         as: :json,
         headers: token_headers(@session)
    assert_response :success
    assert_not_equal 9_999_999, response.parsed_body.dig("score", "points")
  end

  test "rejects a bad session token" do
    post events_api_v1_game_session_url(@session),
         params: { events: [] },
         as: :json,
         headers: { "X-Game-Token" => "nope" }
    assert_response :unauthorized
  end

  test "player creation returns a session token" do
    post api_v1_players_url, params: { name: "Arcade Kid", company: "Saeloun" }, as: :json
    assert_response :created
    assert response.parsed_body.dig("game_session", "token").present?
  end

  private

  def token_headers(session)
    { "X-Game-Token" => session.token }
  end
end
