class LeaderboardChannel < ApplicationCable::Channel
  def subscribed
    scope = %w[live today conference].include?(params[:scope]) ? params[:scope] : "live"
    slug = params[:event].to_s.presence || ConferenceEvent.current.slug
    stream_from "leaderboard:#{slug}:#{scope}"
  end
end
