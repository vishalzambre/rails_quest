class GameSession < ApplicationRecord
  STATUSES = %w[created running completed expired invalid].freeze
  TERMINAL_STATUSES = %w[completed expired invalid].freeze

  belongs_to :player
  belongs_to :conference_event
  belongs_to :game_level, optional: true
  has_many :game_events, dependent: :destroy
  has_many :question_attempts, dependent: :destroy
  has_one :score, dependent: :destroy

  has_secure_token :token, length: 36

  validates :token, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  def created? = status == "created"
  def running? = status == "running"
  def completed? = status == "completed"
  def expired? = status == "expired"
  def marked_invalid? = status == "invalid"

  scope :created, -> { where(status: "created") }
  scope :running, -> { where(status: "running") }
  scope :completed, -> { where(status: "completed") }
  scope :expired, -> { where(status: "expired") }
  scope :invalid_status, -> { where(status: "invalid") }
  scope :playable, -> { where(status: %w[created running]) }
  scope :suspicious, -> { invalid_status.or(where("rejected_event_count >= ?", 8)) }

  delegate :display_name, to: :player

  def to_param
    token
  end

  def terminal?
    TERMINAL_STATUSES.include?(status)
  end

  def running_or_created?
    created? || running?
  end

  # Remaining run time in seconds, based on the configuration snapshot stored at start.
  def remaining_seconds(at: Time.current)
    return duration_seconds.to_i unless started_at

    elapsed = (at - started_at).to_i
    [ duration_seconds.to_i - elapsed, 0 ].max
  end
end
