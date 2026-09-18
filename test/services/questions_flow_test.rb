require "test_helper"

class QuestionsFlowTest < ActiveSupport::TestCase
  test "selects an active question and hides the correct answer" do
    create_question!(prompt: "N+1?", correct_choice_key: "B")
    session = start_session!
    attempt = Questions::Selector.new(game_session: session).call
    refute_includes attempt.question.public_choices.map(&:keys).flatten, "correct"
    assert_nil attempt.question.public_choices.first["correct"]
  end

  test "grades a correct and incorrect answer" do
    question = create_question!
    session = start_session!
    Questions::Selector.new(game_session: session).call
    correct = Questions::Answerer.new(game_session: session, question: question, choice_key: "B").call
    assert correct.correct?
    assert_equal 100, correct.points_awarded

    other = create_question!(difficulty: "medium")
    Questions::Selector.new(game_session: session).call
    wrong = Questions::Answerer.new(game_session: session, question: other, choice_key: "A").call
    assert_not wrong.correct?
    assert_equal(-100, wrong.points_awarded)
  end

  test "cannot answer a question that was not issued" do
    question = create_question!
    session = start_session!
    assert_raises(Questions::Answerer::NotInSession) do
      Questions::Answerer.new(game_session: session, question: question, choice_key: "B").call
    end
  end

  test "cannot answer twice" do
    question = create_question!
    session = start_session!
    Questions::Selector.new(game_session: session).call
    Questions::Answerer.new(game_session: session, question: question, choice_key: "B").call
    assert_raises(Questions::Answerer::AlreadyAnswered) do
      Questions::Answerer.new(game_session: session, question: question, choice_key: "A").call
    end
  end

  test "walks easy medium hard when progression is on" do
    %w[easy medium hard].each { |difficulty| create_question!(difficulty: difficulty) }
    session = start_session!
    first = Questions::Selector.new(game_session: session).call
    second = Questions::Selector.new(game_session: session).call
    third = Questions::Selector.new(game_session: session).call
    assert_equal "easy", first.difficulty
    assert_equal "medium", second.difficulty
    assert_equal "hard", third.difficulty
  end
end
