class RegistrationsController < ApplicationController
  rate_limit to: 20, within: 1.minute, by: -> { request.remote_ip }, only: :create
  before_action :require_event_play_link!, only: %i[new create]
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

    redirect_to event_instructions_path(current_conference_event.slug)
  rescue ActiveRecord::RecordInvalid => error
    @player = error.record
    render :new, status: :unprocessable_entity
  end

  private

  # Play starts only from a shared +/e/:slug+ cabinet link.
  def require_event_play_link!
    return if params[:conference_slug].present?

    redirect_to root_path, alert: "Open an event play link to start a run."
  end

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
