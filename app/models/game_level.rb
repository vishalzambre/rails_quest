class GameLevel < ApplicationRecord
  has_many :game_sessions, dependent: :nullify

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true

  scope :active, -> { where(active: true) }
  scope :playable, -> { where(playable: true, active: true) }
  scope :ordered, -> { order(:sort_order, :id) }

  def self.starting_level
    playable.ordered.first || find_by(key: "ruby_valley")
  end
end
