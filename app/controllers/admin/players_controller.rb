module Admin
  class PlayersController < BaseController
    def index
      @players = Player.where(conference_event: current_conference_event).order(created_at: :desc)
    end

    def show
      @player = Player.find(params[:id])
      @sessions = @player.game_sessions.order(created_at: :desc)
    end
  end
end
