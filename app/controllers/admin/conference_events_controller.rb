module Admin
  class ConferenceEventsController < BaseController
    def index
      @live = current_conference_event
      @events = ConferenceEvent.order(active: :desc, id: :desc)
    end

    def new
      @event = ConferenceEvent.new(time_zone: "Asia/Kolkata", active: true)
    end

    def create
      @event = ConferenceEvent.new(event_params)
      if @event.save
        GameConfiguration.create!(conference_event: @event)
        redirect_to admin_conference_events_path, notice: created_notice
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @event = ConferenceEvent.find(params[:id])
    end

    def update
      @event = ConferenceEvent.find(params[:id])
      if @event.update(event_params)
        redirect_to admin_conference_events_path, notice: "Conference event saved."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def event_params
      params.require(:conference_event).permit(
        :name, :slug, :location, :twitter_handle, :leaderboard_limit, :active
      )
    end

    # Explains how to point the cabinet at a newly registered event without moving old scores.
    def created_notice
      if @event.slug == current_conference_event.slug
        "Conference saved. This cabinet is already live."
      else
        "Conference saved. Past scores stay on their own events. Set CONFERENCE_SLUG=#{@event.slug} and restart web to open this cabinet."
      end
    end
  end
end
