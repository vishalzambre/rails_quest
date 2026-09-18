class GamesController < ApplicationController
  before_action :require_game_session!

  def instructions
    @game_session = current_game_session
    @config = GameConfiguration.current(current_conference_event)
  end

  def show
    @game_session = current_game_session
    @config = GameConfiguration.current(current_conference_event)
    @bootstrap = {
      token: @game_session.token,
      playerName: @game_session.player.display_name,
      levelKey: @game_session.game_level&.key || "ruby_valley",
      levelName: @game_session.game_level&.name || "Ruby Valley",
      config: @config.public_settings,
      resultUrlTemplate: result_path(token: "TOKEN")
    }
  end

  private

  def require_game_session!
    return if current_game_session&.running_or_created?

    redirect_to register_path, alert: "Enter your runner name to play."
  end
end
