module Api
  module V1
    class PlayersController < BaseController
      rate_limit to: 15, within: 1.minute, by: -> { request.remote_ip }, only: :create

      def create
        player = Players::Registrar.new(
          conference_event: current_conference_event,
          attributes: player_params,
          request: request
        ).call
        game_session = GameSessions::Creator.new(player: player, device_info: {}).call

        session[:player_id] = player.id
        session[:game_session_token] = game_session.token

        render json: {
          player: { id: player.id, name: player.display_name, company: player.company },
          game_session: { token: game_session.token, status: game_session.status }
        }, status: :created
      rescue ActiveRecord::RecordInvalid => error
        render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end

      private

      def player_params
        params.permit(:name, :github_username, :email, :company)
      end
    end
  end
end
