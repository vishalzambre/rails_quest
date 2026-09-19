class ApplicationController < ActionController::Base
  helper_method :current_conference_event, :current_player, :current_game_session, :admin_signed_in?,
                :cabinet_home_path, :cabinet_register_path, :cabinet_leaderboard_path

  private

  # Conference this request is playing, viewing, or administering.
  #
  # +/+ is the public leaderboard. Play starts only from a shared +/e/:slug+ link.
  # Admin always uses +CONFERENCE_SLUG+.
  def current_conference_event
    @current_conference_event ||= admin_area? ? ConferenceEvent.current : resolve_play_conference_event
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

  # Cabinet landing: event URL when the attendee arrived from a shared link.
  def cabinet_home_path(event = current_conference_event)
    params[:conference_slug].present? ? event_root_path(event.slug) : root_path
  end

  # Name-entry form. Play is only offered on a shared +/e/:slug+ cabinet.
  def cabinet_register_path(event = current_conference_event)
    params[:conference_slug].present? ? event_register_path(event.slug) : register_path
  end

  # Public leaderboard for the event on this request.
  def cabinet_leaderboard_path(event = current_conference_event, scope: "live")
    unless params[:conference_slug].present?
      return case scope.to_s
      when "today" then today_leaderboard_path
      when "conference" then conference_leaderboard_path
      else leaderboard_path
      end
    end

    case scope.to_s
    when "today" then event_today_leaderboard_path(event.slug)
    when "conference" then event_conference_leaderboard_path(event.slug)
    else event_leaderboard_path(event.slug)
    end
  end

  def admin_area?
    controller_path.start_with?("admin/")
  end

  # Resolves the event from a shared +/e/:slug+ link, an API +event+ param, or the env default.
  def resolve_play_conference_event
    if params[:conference_slug].present?
      event = ConferenceEvent.find_by!(slug: params[:conference_slug])
      claim_conference_event!(event)
      event
    elsif params[:event].present?
      ConferenceEvent.find_by(slug: params[:event]) || ConferenceEvent.current
    else
      ConferenceEvent.current
    end
  end

  # Remembers +event+ for this browser and drops a player from a different conference.
  def claim_conference_event!(event)
    player = current_player
    if player && player.conference_event_id != event.id
      session.delete(:player_id)
      session.delete(:game_session_token)
      @current_player = nil
      @current_game_session = nil
    end
    session[:conference_slug] = event.slug
  end
end
