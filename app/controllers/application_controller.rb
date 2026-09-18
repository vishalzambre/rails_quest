class ApplicationController < ActionController::Base
  helper_method :current_conference_event, :current_player, :current_game_session, :admin_signed_in?

  private

  # Returns the active conference used for registration and leaderboards.
  #
  # Prefers +CONFERENCE_SLUG+, then the first active event, then any event.
  def current_conference_event
    @current_conference_event ||= ConferenceEvent.current
  end

  def current_player
    return unless session[:player_id]

    @current_player ||= Player.find_by(id: session[:player_id])
  end

  def current_game_session
    return unless session[:game_session_token]

    @current_game_session ||= GameSession.find_by(token: session[:game_session_token])
  end

  def admin_signed_in?
    session[:admin] == true
  end
end
