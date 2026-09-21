require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "unscoped play url does not open the game" do
    get "/play"
    assert_redirected_to root_path
  end

  test "event play url without registration sends the player to name entry" do
    get event_play_url(@event.slug)
    assert_redirected_to event_register_path(@event.slug)
  end

  test "event play url opens the run after registering on that cabinet" do
    post event_register_url(@event.slug), params: { player: { name: "Booth" } }
    follow_redirect!
    get event_play_url(@event.slug)
    assert_response :success
    assert_select "#rails-runner"
    assert_select ".touch-controls [data-control=left]", "LEFT"
    assert_select ".touch-controls [data-control=right]", "RIGHT"
    assert_select ".touch-controls [data-control=jump]", "JUMP"
    assert_select "[data-fullscreen]", "FULL"
    assert_select "[data-mute]", "MUTE"
  end

  test "a session from another event cannot open this cabinet" do
    other = ConferenceEvent.create!(name: "Goa Ruby", slug: "goa-ruby-#{SecureRandom.hex(2)}")
    GameConfiguration.create!(conference_event: other)
    post event_register_url(other.slug), params: { player: { name: "Visitor" } }

    get event_play_url(@event.slug)
    assert_redirected_to event_register_path(@event.slug)
  end
end
