class RegistrationsController < ApplicationController
  rate_limit to: 20, within: 1.minute, by: -> { request.remote_ip }, only: :create
  before_action :set_config, only: %i[new create]

  def new
    @player = Player.new
  end

  def create
    player = Players::Registrar.new(
      conference_event: current_conference_event,
      attributes: player_params,
      request: request
    ).call
    game_session = GameSessions::Creator.new(player: player, device_info: device_info).call

    session[:player_id] = player.id
    session[:game_session_token] = game_session.token

    redirect_to instructions_path
  rescue ActiveRecord::RecordInvalid => error
    @player = error.record
    render :new, status: :unprocessable_entity
  end

  private

  # Loads the live scoring table so the register screen can quote duration and lives.
  def set_config
    @config = GameConfiguration.current(current_conference_event)
  end

  def player_params
    params.require(:player).permit(:name, :github_username, :email, :company)
  end

  def device_info
    {
      "user_agent" => request.user_agent,
      "language" => request.headers["HTTP_ACCEPT_LANGUAGE"].to_s.first(80)
    }
  end
end
