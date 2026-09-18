module Api
  module V1
    class BaseController < ApplicationController
      rate_limit to: 180, within: 1.minute, by: -> { request.remote_ip }

      wrap_parameters false

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable
      rescue_from ArgumentError, with: :unprocessable

      private

      def json_error(message, status:)
        render json: { error: message }, status: status
      end

      def not_found
        json_error("not found", status: :not_found)
      end

      def unprocessable(error)
        json_error(error.message, status: :unprocessable_entity)
      end

      def game_session
        @game_session ||= GameSession.find_by!(token: params[:token] || params[:game_session_token] || params[:id])
      end

      def authenticate_game_session!
        provided = request.headers["X-Game-Token"].presence || params[:token]
        json_error("invalid session token", status: :unauthorized) and return unless provided == game_session.token
      end
    end
  end
end
