module Api
  module V1
    class LeaderboardsController < BaseController
      def show
        scope = params[:scope].presence || "conference"
        limit = params[:limit].presence&.to_i
        scores = Leaderboard::Query.new(
          conference_event: current_conference_event,
          scope: scope,
          limit: limit
        ).scores

        render json: {
          scope: scope,
          event: current_conference_event.name,
          entries: scores.each_with_index.map { |score, index| serialize(score, index + 1) }
        }
      end

      private

      def serialize(score, rank)
        {
          rank: rank,
          player: score.player.display_name,
          company: score.player.company,
          score: score.points,
          created_at: score.created_at
        }
      end
    end
  end
end
