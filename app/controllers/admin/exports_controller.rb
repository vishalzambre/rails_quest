module Admin
  class ExportsController < BaseController
    def results
      csv = Exports::GameResults.new(conference_event: current_conference_event).csv
      send_data csv, filename: "rails-runner-#{current_conference_event.slug}-#{Time.zone.today}.csv", type: "text/csv"
    end
  end
end
