export type GameBootstrap = {
  token: string
  playerName: string
  levelKey: string
  levelName: string
  resultUrlTemplate: string
  config: GameTuning
}

export type GameTuning = {
  duration_seconds: number
  lives: number
  question_frequency_seconds: number
  max_questions_per_run: number
  difficulty_progression: boolean
  ruby_points: number
  rails_points: number
  boost_points: number
  special_ruby_points: number
  bug_penalty: number
  production_bug_penalty: number
  question_correct_points: number
  question_wrong_penalty: number
  completion_bonus: number
  time_multiplier: number
}

export type GameState =
  | "START"
  | "COUNTDOWN"
  | "PLAYING"
  | "QUESTION"
  | "PAUSED"
  | "LIFE_LOST"
  | "LEVEL_COMPLETE"
  | "GAME_OVER"
  | "RESULT"

export type QuestionPayload = {
  question_id: number
  prompt: string
  category: string
  difficulty: string
  choices: { key: string; text: string }[]
  points: number
}

export const GAME_WIDTH = 960
export const GAME_HEIGHT = 540
