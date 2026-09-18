module Admin
  class GameSessionsController < BaseController
    def index
      @game_sessions = GameSession.where(conference_event: current_conference_event).order(created_at: :desc).includes(:player, :score)
    end

    def suspicious
      @game_sessions = GameSession.suspicious.where(conference_event: current_conference_event).order(updated_at: :desc).includes(:player)
      render :index
    end

    def show
      @game_session = GameSession.find(params[:id])
      @events = @game_session.game_events.order(:created_at)
      @attempts = @game_session.question_attempts.includes(:question)
    end
  end
end
