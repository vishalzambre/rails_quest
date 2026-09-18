module Api
  module V1
    class QuestionsController < BaseController
      before_action :authenticate_game_session!

      def answer
        question = Question.find(params[:id])
        attempt = Questions::Answerer.new(
          game_session: game_session,
          question: question,
          choice_key: params.require(:choice_key)
        ).call

        render json: {
          correct: attempt.correct,
          points_awarded: attempt.points_awarded,
          server_score: game_session.reload.server_score,
          explanation: question.explanation
        }
      rescue Questions::Answerer::AlreadyAnswered => error
        json_error(error.message, status: :conflict)
      rescue Questions::Answerer::NotInSession => error
        json_error(error.message, status: :forbidden)
      end
    end
  end
end
