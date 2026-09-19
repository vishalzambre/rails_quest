class LeaderboardChannel < ApplicationCable::Channel
  def subscribed
    scope = %w[live today conference].include?(params[:scope]) ? params[:scope] : "live"
    stream_from "leaderboard:#{scope}"
  end
end
