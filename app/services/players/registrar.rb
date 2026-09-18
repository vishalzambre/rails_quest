module Players
  # Registers a conference attendee from the landing form or JSON API.
  class Registrar
    Result = Struct.new(:player, :errors, keyword_init: true)

    # @param conference_event [ConferenceEvent]
    # @param attributes [Hash]
    # @param request [ActionDispatch::Request, nil]
    def initialize(conference_event:, attributes:, request: nil)
      @conference_event = conference_event
      @attributes = attributes
      @request = request
    end

    # Persists a player. Email is stored for organizers only and is never shown on the leaderboard.
    #
    # @return [Player]
    def call
      Player.create!(
        conference_event: @conference_event,
        name: @attributes[:name],
        github_username: @attributes[:github_username],
        email: @attributes[:email],
        company: @attributes[:company],
        user_agent: @request&.user_agent,
        ip_address: @request&.remote_ip
      )
    end
  end
end
