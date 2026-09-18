import type { GameApi } from "../api/Client"

type QueuedEvent = {
  event_type: string
  event_key: string
  occurred_at: string
  metadata?: Record<string, unknown>
}

/**
 * Sends meaningful gameplay events only. Never per-frame packets.
 */
export class GameEventSystem {
  private queue: QueuedEvent[] = []
  private flushing = false

  constructor(private readonly api: GameApi) {}

  record(eventType: string, metadata: Record<string, unknown> = {}) {
    this.queue.push({
      event_type: eventType,
      event_key: crypto.randomUUID(),
      occurred_at: new Date().toISOString(),
      metadata
    })
  }

  async flush() {
    if (this.flushing || this.queue.length === 0) return
    this.flushing = true
    const batch = this.queue.splice(0, this.queue.length)
    try {
      await this.api.sendEvents(batch)
    } catch {
      this.queue.unshift(...batch)
    } finally {
      this.flushing = false
    }
  }
}
