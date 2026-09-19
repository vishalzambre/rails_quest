module Broadcasts
  # Pushes a newly published score to the TV leaderboard stream.
  class Leaderboard
    def initialize(score:)
      @score = score
    end

    def call
      payload = {
        type: "score",
        high_score: high_score?,
        entry: {
          player: @score.player.display_name,
          company: @score.player.company,
          points: @score.points,
          rank: ::Leaderboard::Query.new(conference_event: @score.conference_event, scope: "conference").rank_for(@score)
        }
      }

      %w[live conference].each { |scope| ActionCable.server.broadcast("leaderboard:#{scope}", payload) }
      ActionCable.server.broadcast("leaderboard:today", payload) if @score.created_at.to_date == Time.zone.today
    rescue StandardError => error
      Rails.logger.warn("Leaderboard broadcast skipped: #{error.message}")
    end

    private

    def high_score?
      top = Score.for_event(@score.conference_event).published.ranked.first
      top&.id == @score.id
    end
  end
end
