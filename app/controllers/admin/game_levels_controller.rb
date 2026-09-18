module Admin
  class GameLevelsController < BaseController
    def index
      @levels = GameLevel.ordered
    end

    def edit
      @level = GameLevel.find(params[:id])
    end

    def update
      @level = GameLevel.find(params[:id])
      if @level.update(level_params)
        redirect_to admin_game_levels_path, notice: "Level updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def level_params
      params.require(:game_level).permit(:name, :subtitle, :description, :active, :playable, :sort_order)
    end
  end
end
