module Api
  module V1
    class StatsController < BaseController
      def show
        best = Leaderboard::Query.new(conference_event: current_conference_event, scope: "today", limit: 1).scores.first
        render json: {
          best_score_today: best&.points.to_i,
          players_played: GameSession.where(conference_event: current_conference_event).where.not(started_at: nil).select(:player_id).distinct.count
        }
      end
    end
  end
end
