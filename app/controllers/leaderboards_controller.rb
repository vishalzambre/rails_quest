class LeaderboardsController < ApplicationController
  def show
    load_board("conference")
  end

  def today
    load_board("today")
    render :show
  end

  def conference
    load_board("conference")
    render :show
  end

  private

  def load_board(scope)
    @scope = scope
    @event = current_conference_event
    limit = params[:limit].presence&.to_i
    limit = 10 if params[:top] == "10"
    @scores = Leaderboard::Query.new(conference_event: @event, scope: @scope, limit: limit).scores
  end
end
