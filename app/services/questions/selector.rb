module Questions
  # Picks the next challenge for a running session without exposing the correct answer.
  class Selector
    class LimitReached < StandardError; end
    class NoneAvailable < StandardError; end

    def initialize(game_session:)
      @game_session = game_session
      @config = GameConfiguration.current(game_session.conference_event)
    end

    # Creates a {QuestionAttempt} and returns the question shown to the player.
    #
    # Difficulty walks easy → medium → hard when progression is enabled.
    #
    # @return [QuestionAttempt]
    def call
      raise LimitReached, "no more questions in this run" if @game_session.question_attempts.count >= @config.max_questions_per_run

      question = next_question
      raise NoneAvailable, "no active questions" unless question

      @game_session.question_attempts.create!(
        question: question,
        difficulty: question.difficulty,
        asked_at: Time.current
      )
    end

    private

    def next_question
      used_ids = @game_session.question_attempts.select(:question_id)
      pool = Question.active.where.not(id: used_ids)
      pool = pool.by_difficulty(next_difficulty) if @config.difficulty_progression?
      pool = Question.active.where.not(id: used_ids) if pool.none?
      pool.order("RANDOM()").first
    end

    def next_difficulty
      index = @game_session.question_attempts.count
      Question::DIFFICULTIES[index] || "hard"
    end
  end
end
