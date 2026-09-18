module Admin
  class LeaderboardsController < BaseController
    def show
      @scores = Leaderboard::Query.new(conference_event: current_conference_event, scope: "conference").scores
    end

    def destroy
      Score.for_event(current_conference_event).update_all(published: false)
      redirect_to admin_leaderboard_path, notice: "Leaderboard unpublished for this event."
    end
  end
end
