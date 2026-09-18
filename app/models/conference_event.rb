class ConferenceEvent < ApplicationRecord
  has_many :players, dependent: :restrict_with_error
  has_many :game_sessions, dependent: :restrict_with_error
  has_many :scores, dependent: :restrict_with_error
  has_one :game_configuration, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :leaderboard_limit, numericality: { greater_than: 0, less_than_or_equal_to: 500 }

  scope :active, -> { where(active: true) }

  # Returns the event used by the public game, creating the Deccan default if needed.
  def self.current
    slug = ENV.fetch("CONFERENCE_SLUG", "deccan-rails-conf")
    find_by(slug: slug) || active.first || create_default!
  end

  # Seeds the placeholder Deccan Rails Conf event used in development and first boot.
  def self.create_default!
    create!(
      name: "Deccan Rails Conf",
      slug: ENV.fetch("CONFERENCE_SLUG", "deccan-rails-conf"),
      location: "Hyderabad",
      time_zone: "Asia/Kolkata",
      starts_at: Time.zone.parse("2026-09-18"),
      ends_at: Time.zone.parse("2026-09-20").end_of_day,
      active: true
    )
  end
end
