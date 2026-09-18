module Questions
  # Grades an in-run challenge using the server copy of the question, never the client.
  class Answerer
    class AlreadyAnswered < StandardError; end
    class NotInSession < StandardError; end

    def initialize(game_session:, question:, choice_key:)
      @game_session = game_session
      @question = question
      @choice_key = choice_key.to_s
    end

    # Records the selected choice and the signed point award.
    #
    # @return [QuestionAttempt]
    def call
      attempt = @game_session.question_attempts.find_by(question: @question)
      raise NotInSession, "question was not issued for this run" unless attempt
      raise AlreadyAnswered, "question already answered" if attempt.answered?

      correct = @question.correct?(@choice_key)
      points = if correct
        @question.points.presence || GameConfiguration.current(@game_session.conference_event).question_correct_points
      else
        -( @question.wrong_points.presence || GameConfiguration.current(@game_session.conference_event).question_wrong_penalty )
      end

      attempt.update!(
        choice_key: @choice_key,
        correct: correct,
        points_awarded: points,
        answered_at: Time.current
      )

      @game_session.game_events.create!(
        event_type: "question_answered",
        event_key: "answer-#{attempt.id}",
        occurred_at: Time.current,
        accepted: true,
        points_delta: 0,
        metadata: { question_id: @question.id, correct: correct }
      )

      @game_session.update!(server_score: Scoring::Calculator.new(game_session: @game_session.reload).running_total)
      attempt
    end
  end
end
