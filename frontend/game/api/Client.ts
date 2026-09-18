import type { GameBootstrap, QuestionPayload } from "../types"

const csrfToken = () =>
  document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content || ""

/**
 * Talks to the Rails JSON API. The Phaser HUD score is never submitted as truth.
 */
export class GameApi {
  constructor(private readonly bootstrap: GameBootstrap) {}

  async start(): Promise<void> {
    await this.request("POST", `/api/v1/game_sessions/${this.bootstrap.token}/start`)
  }

  async sendEvents(events: Record<string, unknown>[]): Promise<{ server_score: number }> {
    if (events.length === 0) return { server_score: 0 }
    return this.request("POST", `/api/v1/game_sessions/${this.bootstrap.token}/events`, { events })
  }

  async challenge(): Promise<QuestionPayload> {
    return this.request("POST", `/api/v1/game_sessions/${this.bootstrap.token}/challenge`)
  }

  async answer(questionId: number, choiceKey: string) {
    return this.request("POST", `/api/v1/game_sessions/${this.bootstrap.token}/questions/${questionId}/answer`, {
      choice_key: choiceKey
    })
  }

  async finish(outcome: "completed" | "finished", clientScore: number) {
    return this.request("POST", `/api/v1/game_sessions/${this.bootstrap.token}/finish`, {
      outcome,
      client_score: clientScore
    })
  }

  resultUrl(): string {
    return this.bootstrap.resultUrlTemplate.replace("TOKEN", this.bootstrap.token)
  }

  private async request(method: string, url: string, body?: unknown) {
    const response = await fetch(url, {
      method,
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": csrfToken(),
        "X-Game-Token": this.bootstrap.token
      },
      body: body ? JSON.stringify(body) : undefined
    })
    const data = await response.json().catch(() => ({}))
    if (!response.ok) {
      throw new Error(data.error || `Request failed (${response.status})`)
    }
    return data
  }
}
