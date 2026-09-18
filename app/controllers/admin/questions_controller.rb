module Admin
  class QuestionsController < BaseController
    before_action :set_question, only: %i[edit update destroy toggle]

    def index
      @questions = Question.order(:category, :difficulty, :id)
    end

    def new
      @question = Question.new(choices: default_choices, difficulty: "easy", category: "Rails")
    end

    def create
      @question = Question.new(question_params)
      if @question.save
        redirect_to admin_questions_path, notice: "Question added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @question.update(question_params)
        redirect_to admin_questions_path, notice: "Question updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @question.destroy!
      redirect_to admin_questions_path, notice: "Question removed."
    end

    def toggle
      @question.update!(active: !@question.active?)
      redirect_to admin_questions_path, notice: "Question #{@question.active? ? "activated" : "deactivated"}."
    end

    private

    def set_question
      @question = Question.find(params[:id])
    end

    def question_params
      permitted = params.require(:question).permit(:prompt, :category, :difficulty, :correct_choice_key, :points, :wrong_points, :active, :explanation, :choices_text)
      permitted[:choices] = parse_choices(permitted.delete(:choices_text)) if permitted[:choices_text]
      permitted
    end

    def parse_choices(text)
      text.to_s.split("\n").map(&:strip).reject(&:blank?).map.with_index do |line, index|
        key = line[/\A([A-D])[.):]/i, 1]&.upcase || (index + 65).chr
        text_value = line.sub(/\A[A-D][.):]\s*/i, "")
        { "key" => key, "text" => text_value }
      end
    end

    def default_choices
      %w[A B C D].map { |key| { "key" => key, "text" => "" } }
    end
  end
end
