module Exports
  # CSV export of completed runs for organizers. Email is included for staff only.
  class GameResults
    def initialize(conference_event:)
      @event = conference_event
    end

    # @return [String]
    def csv
      require "csv"

      CSV.generate(headers: true) do |rows|
        rows << %w[rank player github email company score gems tracks questions time_remaining completed status demo published]
        Score.for_event(@event).ranked.includes(:player, :game_session).each_with_index do |score, index|
          rows << [
            index + 1,
            score.player.name,
            score.player.github_username,
            score.player.email,
            score.player.company,
            score.points,
            score.gems_count,
            score.tracks_count,
            score.questions_summary,
            score.time_remaining,
            score.level_completed,
            score.game_session.status,
            score.demo,
            score.published
          ]
        end
      end
    end
  end
end
