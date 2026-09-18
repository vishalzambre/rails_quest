class LeaderboardChannel < ApplicationCable::Channel
  def subscribed
    scope = %w[today conference].include?(params[:scope]) ? params[:scope] : "conference"
    stream_from "leaderboard:#{scope}"
  end
end
