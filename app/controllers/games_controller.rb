class GamesController < ApplicationController
  before_action :require_playable_session!

  def instructions
    @game_session = playable_game_session
    @config = GameConfiguration.current(@game_session.conference_event)
  end

  def show
    @game_session = playable_game_session
    @config = GameConfiguration.current(@game_session.conference_event)
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

  # Blocks /e/:slug/play unless this browser just registered a created/running run
  # for that same event.
  def require_playable_session!
    game = playable_game_session
    slug = params[:conference_slug].to_s
    return if game && game.conference_event.slug == slug

    if slug.present? && ConferenceEvent.exists?(slug: slug)
      redirect_to event_register_path(slug), alert: "Enter your runner name to play."
    else
      redirect_to root_path, alert: "Open an event play link to start a run."
    end
  end

  # Session cookie must point at a live run owned by the same player.
  def playable_game_session
    game = current_game_session
    player = current_player
    return unless game&.running_or_created?
    return unless player && game.player_id == player.id
    return unless game.conference_event_id == player.conference_event_id

    game
  end
end
