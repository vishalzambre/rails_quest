class Question < ApplicationRecord
  CATEGORIES = %w[Ruby Rails ActiveRecord SQL PostgreSQL Redis Sidekiq AWS Performance Security SystemDesign].freeze
  DIFFICULTIES = %w[easy medium hard].freeze

  has_many :question_attempts, dependent: :restrict_with_error

  validates :prompt, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :difficulty, presence: true, inclusion: { in: DIFFICULTIES }
  validates :correct_choice_key, presence: true
  validates :choices, presence: true
  validate :choices_include_correct_key
  validate :four_choices

  scope :active, -> { where(active: true) }
  scope :by_difficulty, ->(difficulty) { where(difficulty: difficulty) }

  # Choices without the correct key, safe to send to the Phaser client.
  def public_choices
    Array(choices).map { |choice| choice.slice("key", "text") }
  end

  # Admin textarea representation of +choices+.
  def choices_text
    Array(choices).map { |choice| "#{choice["key"]}. #{choice["text"]}" }.join("\n")
  end

  def correct?(choice_key)
    choice_key.to_s == correct_choice_key
  end

  private

  def choices_include_correct_key
    keys = Array(choices).filter_map { |choice| choice["key"] || choice[:key] }
    return if keys.include?(correct_choice_key)

    errors.add(:correct_choice_key, "must match one of the choice keys")
  end

  def four_choices
    return if Array(choices).size.between?(2, 6)

    errors.add(:choices, "must include between 2 and 6 answers")
  end
end
