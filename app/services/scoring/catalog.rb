module Scoring
  # Maps accepted gameplay events onto the conference scoring configuration.
  class Catalog
    POSITIVE = {
      "ruby_collected" => :ruby_points,
      "rails_collected" => :rails_points,
      "boost_collected" => :boost_points,
      "special_collected" => :special_ruby_points,
      "level_completed" => :completion_bonus
    }.freeze

    NEGATIVE = {
      "bug_hit" => :bug_penalty,
      "production_bug_hit" => :production_bug_penalty
    }.freeze

    def initialize(game_session:)
      @config = GameConfiguration.current(game_session.conference_event)
    end

    # @param event_type [String]
    # @return [Integer] signed point delta for one accepted event
    def delta_for(event_type)
      if (field = POSITIVE[event_type.to_s])
        @config.public_send(field)
      elsif (field = NEGATIVE[event_type.to_s])
        -@config.public_send(field)
      else
        0
      end
    end
  end
end
