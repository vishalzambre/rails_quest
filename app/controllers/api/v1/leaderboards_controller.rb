module Api
  module V1
    class LeaderboardsController < BaseController
      def show
        scope = params[:scope].presence || "live"
        limit = params[:limit].presence&.to_i
        query = Leaderboard::Query.new(
          conference_event: current_conference_event,
          scope: scope,
          limit: limit
        )
        scores = query.scores
        latest = query.latest

        render json: {
          scope: scope,
          event: current_conference_event.name,
          updated_at: Time.current.iso8601,
          latest: latest && serialize(latest, query.rank_for(latest)),
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
