require "test_helper"

class Admin::ConferenceEventsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_admin }

  test "registers a new conference without moving existing scores" do
    keep = publish_live_score

    assert_difference -> { ConferenceEvent.count } => 1, -> { GameConfiguration.count } => 1 do
      post admin_conference_events_url, params: {
        conference_event: {
          name: "Goa Ruby",
          twitter_handle: "@hideccanqueen",
          location: "Goa"
        }
      }
    end

    created = ConferenceEvent.find_by!(name: "Goa Ruby")
    assert_equal "hideccanqueen", created.twitter_handle
    assert_equal "goa-ruby", created.slug
    assert_equal keep.conference_event_id, keep.reload.conference_event_id
    assert_redirected_to admin_conference_events_path
  end

  test "saves an X handle on an existing conference" do
    patch admin_conference_event_url(@event), params: {
      conference_event: { twitter_handle: "https://x.com/hideccanqueen" }
    }

    assert_redirected_to admin_conference_events_path
    assert_equal "hideccanqueen", @event.reload.twitter_handle
  end

  private

  def sign_in_admin
    post admin_login_url, params: { username: "admin", password: "changeme" }
  end

  def publish_live_score
    session = start_session!
    session.update!(status: :completed)
    Score.create!(
      game_session: session,
      player: @player,
      conference_event: @event,
      points: 120,
      published: true
    )
  end
end
