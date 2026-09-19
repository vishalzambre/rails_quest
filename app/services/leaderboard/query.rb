module Leaderboard
  # Reads published scores from PostgreSQL for the public board and TV display.
  class Query
    def initialize(conference_event:, scope: "conference", limit: nil)
      @conference_event = conference_event
      @scope = scope.to_s
      @limit = limit
    end

    # @return [ActiveRecord::Relation<Score>]
    def scores
      relation = Score.for_event(@conference_event).published.ranked.includes(:player)
      relation = relation.competitive unless GameConfiguration.current(@conference_event).include_demo_on_leaderboard?
      relation = relation.today if @scope == "today"
      relation.limit(resolved_limit)
    end

    # Most recently published score, used by the LIVE ticker.
    #
    # @return [Score, nil]
    def latest
      relation = Score.for_event(@conference_event).published.includes(:player).order(created_at: :desc)
      relation = relation.competitive unless GameConfiguration.current(@conference_event).include_demo_on_leaderboard?
      relation = relation.today if @scope == "today"
      relation.first
    end

    # 1-based rank for a published score, or nil when the run is unpublished.
    #
    # @param score [Score]
    # @return [Integer, nil]
    def rank_for(score)
      return unless score&.published?

      relation = Score.for_event(@conference_event).published
      relation = relation.competitive unless GameConfiguration.current(@conference_event).include_demo_on_leaderboard?
      relation.where("points > ? OR (points = ? AND created_at < ?)", score.points, score.points, score.created_at).count + 1
    end

    def resolved_limit
      @limit.presence || (@scope == "top10" ? 10 : @conference_event.leaderboard_limit)
    end
  end
end
