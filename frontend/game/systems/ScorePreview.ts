import type { GameTuning } from "../types"

/** Client HUD preview. Rails recalculates the published score from events. */
export const previewDelta = (config: GameTuning, eventType: string): number => {
  const map: Record<string, number> = {
    ruby_collected: config.ruby_points,
    rails_collected: config.rails_points,
    boost_collected: config.boost_points,
    special_collected: config.special_ruby_points,
    bug_hit: -config.bug_penalty,
    production_bug_hit: -config.production_bug_penalty,
    level_completed: config.completion_bonus
  }
  return map[eventType] ?? 0
}
