class Score < ApplicationRecord
  belongs_to :game_session
  belongs_to :player
  belongs_to :conference_event

  validates :game_session_id, uniqueness: true
  validates :points, numericality: { only_integer: true }

  scope :published, -> { where(published: true) }
  scope :competitive, -> { published.where(demo: false) }
  scope :for_event, ->(event) { where(conference_event: event) }
  scope :today, -> { where("scores.created_at >= ?", Time.current.beginning_of_day) }
  scope :ranked, -> { order(points: :desc, created_at: :asc) }

  def questions_summary
    "#{questions_correct}/#{questions_asked}"
  end
end
