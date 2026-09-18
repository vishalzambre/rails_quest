module Admin
  class AnalyticsController < BaseController
    def show
      @analytics = Analytics::Summary.new(conference_event: current_conference_event).call
    end
  end
end
