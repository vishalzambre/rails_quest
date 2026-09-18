module Admin
  class DashboardController < BaseController
    def show
      @event = current_conference_event
      @analytics = Analytics::Summary.new(conference_event: @event).call
      @recent_sessions = GameSession.where(conference_event: @event).order(created_at: :desc).limit(12)
      @suspicious = GameSession.suspicious.where(conference_event: @event).order(updated_at: :desc).limit(8)
    end
  end
end
