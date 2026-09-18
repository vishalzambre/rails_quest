class ResultsController < ApplicationController
  def show
    @game_session = GameSession.find_by!(token: params[:token])
    @score = @game_session.score
    @rank = @score && Leaderboard::Query.new(conference_event: @game_session.conference_event).rank_for(@score)
    @config = GameConfiguration.current(@game_session.conference_event)
  end
end
