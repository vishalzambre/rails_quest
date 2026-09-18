require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "requires a name" do
    player = Player.new(conference_event: @event, name: "")
    assert_not player.valid?
  end

  test "strips github at-sign and never uses email as display name" do
    player = Player.create!(conference_event: @event, name: "Vishal", github_username: "@vishal", email: "hidden@example.com")
    assert_equal "vishal", player.github_username
    assert_equal "vishal", player.display_name
    assert_not_includes player.display_name, "@example.com"
  end
end
