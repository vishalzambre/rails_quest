class GameConfiguration < ApplicationRecord
  belongs_to :conference_event

  validates :duration_seconds, numericality: { greater_than: 20, less_than_or_equal_to: 300 }
  validates :lives, numericality: { greater_than: 0, less_than_or_equal_to: 9 }
  validates :question_frequency_seconds, numericality: { greater_than: 5 }
  validates :max_questions_per_run, numericality: { greater_than: 0, less_than_or_equal_to: 10 }
  validates :time_multiplier, numericality: { greater_than_or_equal_to: 0 }

  # Fetches or builds the configuration row for the current conference.
  def self.current(event = ConferenceEvent.current)
    find_by(conference_event: event) || create_default!(event)
  end

  # Inserts the MVP scoring table described in the game brief.
  def self.create_default!(event)
    create!(conference_event: event)
  end

  # Values the Phaser client is allowed to read. Penalties are positive numbers
  # on the server and negated by the client HUD.
  def public_settings
    {
      duration_seconds: duration_seconds,
      lives: lives,
      question_frequency_seconds: question_frequency_seconds,
      max_questions_per_run: max_questions_per_run,
      difficulty_progression: difficulty_progression,
      ruby_points: ruby_points,
      rails_points: rails_points,
      boost_points: boost_points,
      special_ruby_points: special_ruby_points,
      bug_penalty: bug_penalty,
      production_bug_penalty: production_bug_penalty,
      question_correct_points: question_correct_points,
      question_wrong_penalty: question_wrong_penalty,
      completion_bonus: completion_bonus,
      time_multiplier: time_multiplier
    }
  end
end
