module Admin
  class GameConfigurationsController < BaseController
    def show
      @config = GameConfiguration.current(current_conference_event)
    end

    def update
      @config = GameConfiguration.current(current_conference_event)
      if @config.update(config_params)
        redirect_to admin_game_configuration_path, notice: "Scoring and run settings saved."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def config_params
      params.require(:game_configuration).permit(
        :duration_seconds, :lives, :question_frequency_seconds, :max_questions_per_run,
        :difficulty_progression, :ruby_points, :rails_points, :boost_points, :special_ruby_points,
        :bug_penalty, :production_bug_penalty, :question_correct_points, :question_wrong_penalty,
        :completion_bonus, :time_multiplier, :include_demo_on_leaderboard
      )
    end
  end
end
