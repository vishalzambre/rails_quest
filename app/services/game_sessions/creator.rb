module GameSessions
  # Opens a new run for a player against the current scoring configuration.
  class Creator
    # @param player [Player]
    # @param device_info [Hash]
    def initialize(player:, device_info: {})
      @player = player
      @device_info = device_info
    end

    # Builds a +created+ session with a secure token. The run does not start until {Starter} runs.
    #
    # @return [GameSession]
    def call
      config = GameConfiguration.current(@player.conference_event)
      @player.game_sessions.create!(
        conference_event: @player.conference_event,
        game_level: GameLevel.starting_level,
        status: :created,
        lives_remaining: config.lives,
        duration_seconds: config.duration_seconds,
        device_info: sanitized_device_info,
        expires_at: 30.minutes.from_now
      )
    end

    private

    def sanitized_device_info
      info = @device_info.is_a?(Hash) ? @device_info : {}
      info.slice("user_agent", "language", "platform", "viewport").presence || {}
    end
  end
end
