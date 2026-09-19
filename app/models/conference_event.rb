class ConferenceEvent < ApplicationRecord
  has_many :players, dependent: :restrict_with_error
  has_many :game_sessions, dependent: :restrict_with_error
  has_many :scores, dependent: :restrict_with_error
  has_one :game_configuration, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :leaderboard_limit, numericality: { greater_than: 0, less_than_or_equal_to: 500 }
  validates :twitter_handle, length: { maximum: 15 }, allow_blank: true,
            format: { with: /\A[A-Za-z0-9_]+\z/, message: "must be a username without @" }

  scope :active, -> { where(active: true) }

  before_validation :assign_slug, on: :create
  before_validation :normalize_twitter_handle

  # Live cabinet for registration, play, and the public leaderboard.
  #
  # One event is current at a time (+CONFERENCE_SLUG+, else the first active
  # row). Other events stay in the database with their own players and scores.
  def self.current
    slug = ENV.fetch("CONFERENCE_SLUG", "deccan-rails-conf")
    find_by(slug: slug) || active.first || create_default!
  end

  # Seeds the placeholder Deccan Rails Conf event used in development and first boot.
  def self.create_default!
    create!(
      name: "Deccan Rails Conf",
      slug: ENV.fetch("CONFERENCE_SLUG", "deccan-rails-conf"),
      location: "Pune",
      time_zone: "Asia/Kolkata",
      twitter_handle: "hideccanqueen",
      starts_at: Time.zone.parse("2026-09-18"),
      ends_at: Time.zone.parse("2026-09-20").end_of_day,
      active: true
    )
  end

  # Mention string for tweets, or nil when this event has no X account.
  #
  # @return [String, nil]
  def twitter_mention
    twitter_handle.present? ? "@#{twitter_handle}" : nil
  end

  # Brag copy for a finished run. Appends the event X handle when one is saved.
  #
  # @param points [String, Integer] formatted or raw score
  # @return [String]
  def score_share_text(points:)
    sentence = "I scored #{points} in Rails Runner at #{name}."
    mention = twitter_mention
    mention ? "#{sentence} #{mention}" : sentence
  end

  # X/Twitter Web Intent URL for posting +text+ with this event tagged.
  #
  # @param text [String] full tweet body, including the mention when present
  # @param url [String, nil] page attached to the post
  # @return [String, nil] intent URL, or nil when no handle is configured
  def twitter_share_url(text:, url: nil)
    return if twitter_handle.blank?

    params = { text: text, related: twitter_handle }
    params[:url] = url if url.present?
    "https://twitter.com/intent/tweet?#{params.to_query}"
  end

  # Public cabinet URL attendees open (or scan) to play this event.
  #
  # @param host [String] origin such as https://game.example.com
  # @return [String]
  def play_url(host: ENV.fetch("APP_HOST", "http://localhost:3000"))
    "#{host.to_s.chomp('/')}/e/#{slug}"
  end

  private

  # Fills +slug+ from the name when registering a new conference.
  def assign_slug
    self.slug = name.to_s.parameterize if slug.blank?
  end

  # Accepts @name, a profile URL, or a bare username and stores the username only.
  def normalize_twitter_handle
    raw = twitter_handle.to_s.strip
    raw = raw.sub(%r{\Ahttps?://(?:www\.)?(?:x|twitter)\.com/}i, "")
    raw = raw.split(%r{[/?#]}).first.to_s
    self.twitter_handle = raw.delete_prefix("@").presence
  end
end
