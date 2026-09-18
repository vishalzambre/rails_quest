class Player < ApplicationRecord
  belongs_to :conference_event
  has_many :game_sessions, dependent: :destroy
  has_many :scores, dependent: :destroy

  validates :name, presence: true, length: { maximum: 24 }
  validates :github_username, length: { maximum: 39 }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :company, length: { maximum: 80 }, allow_blank: true

  before_validation :normalize_identity

  scope :demo, -> { where(demo: true) }
  scope :real, -> { where(demo: false) }

  # Public leaderboard label. Never includes email.
  def display_name
    github_username.presence || name
  end

  private

  def normalize_identity
    self.name = name.to_s.strip
    self.github_username = github_username.to_s.strip.delete_prefix("@").presence
    self.email = email.to_s.strip.downcase.presence
    self.company = company.to_s.strip.presence
  end
end
