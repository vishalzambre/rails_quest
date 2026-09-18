class PagesController < ApplicationController
  def home
    @best_today = Leaderboard::Query.new(conference_event: current_conference_event, scope: "today", limit: 1).scores.first
    @players_played = GameSession.where(conference_event: current_conference_event).where.not(started_at: nil).select(:player_id).distinct.count
    @top_preview = Leaderboard::Query.new(conference_event: current_conference_event, scope: "top10", limit: 5).scores
  end
end
