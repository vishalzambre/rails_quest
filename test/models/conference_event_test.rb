require "test_helper"

class ConferenceEventTest < ActiveSupport::TestCase
  test "normalizes pasted X handles and profile urls" do
    @event.twitter_handle = "https://x.com/hideccanqueen"
    assert @event.valid?
    assert_equal "hideccanqueen", @event.twitter_handle
    assert_equal "@hideccanqueen", @event.twitter_mention
  end

  test "builds a tweet intent that mentions the event handle" do
    @event.update!(twitter_handle: "@hideccanqueen")
    text = @event.score_share_text(points: "275")
    url = @event.twitter_share_url(text: text, url: "https://example.com/leaderboard")

    assert_includes text, "@hideccanqueen"
    assert_includes url, "twitter.com/intent/tweet"
    assert_includes CGI.unescape(url), "@hideccanqueen"
    assert_includes url, "related=hideccanqueen"
  end

  test "omits the X share url when no handle is saved" do
    @event.update!(twitter_handle: "")
    assert_nil @event.twitter_mention
    assert_nil @event.twitter_share_url(text: "I scored 10.")
  end

  test "builds a slug when registering a conference without one" do
    event = ConferenceEvent.create!(name: "Goa Ruby Night", location: "Goa")
    assert_equal "goa-ruby-night", event.slug
  end
end
