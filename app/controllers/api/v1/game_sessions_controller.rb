module Api
  module V1
    class GameSessionsController < BaseController
      before_action :authenticate_game_session!, except: :create

      def create
        player = current_player || Player.find(params.require(:player_id))
        game_session = GameSessions::Creator.new(player: player, device_info: params[:device_info] || {}).call
        session[:game_session_token] = game_session.token

        render json: serialize_session(game_session), status: :created
      end

      def show
        render json: serialize_session(game_session)
      end

      def start
        GameSessions::Starter.new(game_session: game_session).call
        render json: serialize_session(game_session.reload)
      rescue GameSessions::Starter::AlreadyStarted
        render json: serialize_session(game_session)
      rescue GameSessions::Starter::NotStartable => error
        json_error(error.message, status: :unprocessable_entity)
      end

      def events
        result = GameSessions::EventRecorder.new(game_session: game_session, events: event_payload).call
        render json: {
          server_score: result.server_score,
          status: result.status,
          accepted: result.events.count(&:accepted),
          rejected: result.events.count { |event| !event.accepted }
        }
      end

      def finish
        score = GameSessions::Finisher.new(
          game_session: game_session,
          client_score: params[:client_score],
          outcome: params[:outcome].presence || "finished"
        ).call

        render json: {
          status: game_session.reload.status,
          score: serialize_score(score),
          rank: Leaderboard::Query.new(conference_event: game_session.conference_event).rank_for(score),
          result_url: result_url(token: game_session.token)
        }
      rescue GameSessions::Finisher::AlreadyFinished
        score = game_session.score
        render json: {
          status: game_session.status,
          score: serialize_score(score),
          rank: Leaderboard::Query.new(conference_event: game_session.conference_event).rank_for(score),
          result_url: result_url(token: game_session.token)
        }
      rescue GameSessions::Finisher::NotRunning => error
        json_error(error.message, status: :unprocessable_entity)
      end

      def challenge
        attempt = Questions::Selector.new(game_session: game_session).call
        question = attempt.question
        render json: {
          question_id: question.id,
          prompt: question.prompt,
          category: question.category,
          difficulty: question.difficulty,
          choices: question.public_choices,
          points: question.points
        }
      rescue Questions::Selector::LimitReached, Questions::Selector::NoneAvailable => error
        json_error(error.message, status: :unprocessable_entity)
      end

      private

      def event_payload
        permitted = params.permit(events: [ :event_type, :event_key, :occurred_at, { metadata: {} } ])
        Array(permitted[:events])
      end

      def serialize_session(session)
        {
          token: session.token,
          status: session.status,
          server_score: session.server_score,
          lives_remaining: session.lives_remaining,
          duration_seconds: session.duration_seconds,
          started_at: session.started_at,
          config: GameConfiguration.current(session.conference_event).public_settings,
          level: { key: session.game_level&.key, name: session.game_level&.name }
        }
      end

      def serialize_score(score)
        return unless score

        {
          points: score.points,
          gems_count: score.gems_count,
          tracks_count: score.tracks_count,
          questions_correct: score.questions_correct,
          questions_asked: score.questions_asked,
          time_remaining: score.time_remaining,
          time_bonus: score.time_bonus,
          completion_bonus: score.completion_bonus,
          level_completed: score.level_completed,
          published: score.published
        }
      end
    end
  end
end
