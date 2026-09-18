ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    setup :build_world

    private

    def build_world
      @event = ConferenceEvent.create!(
        name: "Deccan Rails Conf",
        slug: "event-#{SecureRandom.hex(4)}",
        active: true
      )
      @config = GameConfiguration.create!(conference_event: @event)
      @level = GameLevel.create!(key: "ruby_valley-#{SecureRandom.hex(3)}", name: "Ruby Valley", playable: true, active: true)
      @player = Player.create!(conference_event: @event, name: "Tester")
    end

    def create_question!(attrs = {})
      n = SecureRandom.hex(3)
      Question.create!(
        {
          prompt: "Prompt #{n}?",
          category: "Rails",
          difficulty: "easy",
          choices: [
            { "key" => "A", "text" => "No" },
            { "key" => "B", "text" => "Yes" },
            { "key" => "C", "text" => "Maybe" },
            { "key" => "D", "text" => "Never" }
          ],
          correct_choice_key: "B",
          points: 100,
          wrong_points: 100,
          active: true
        }.merge(attrs)
      )
    end

    def start_session!
      session = GameSessions::Creator.new(player: @player).call
      GameSessions::Starter.new(game_session: session).call
      session.reload
    end
  end
end
