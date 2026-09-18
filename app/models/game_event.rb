class GameEvent < ApplicationRecord
  TYPES = %w[
    game_started
    ruby_collected
    rails_collected
    boost_collected
    special_collected
    bug_hit
    production_bug_hit
    technical_debt_hit
    question_started
    question_answered
    life_lost
    level_completed
    game_finished
  ].freeze

  belongs_to :game_session

  validates :event_type, presence: true
  validates :event_key, presence: true, uniqueness: { scope: :game_session_id }
  validates :occurred_at, presence: true

  scope :accepted, -> { where(accepted: true) }
  scope :of_type, ->(type) { where(event_type: type) }
end
