class QuestionAttempt < ApplicationRecord
  belongs_to :game_session
  belongs_to :question

  validates :question_id, uniqueness: { scope: :game_session_id }
  validates :asked_at, presence: true

  scope :answered, -> { where.not(answered_at: nil) }
  scope :unanswered, -> { where(answered_at: nil) }
  scope :correct, -> { where(correct: true) }

  def answered?
    answered_at.present?
  end
end
