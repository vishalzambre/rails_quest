import { createConsumer } from "@rails/actioncable"

type Entry = {
  rank: number
  player: string
  company?: string | null
  score: number
  created_at?: string
}

const root = document.querySelector<HTMLElement>("[data-leaderboard]")
if (root) {
  const banner = root.querySelector<HTMLElement>("[data-high-banner]")
  const tbody = root.querySelector<HTMLElement>("[data-rows]")
  const empty = root.querySelector<HTMLElement>("[data-empty]")
  const stamp = root.querySelector<HTMLElement>("[data-updated]")
  const badge = root.querySelector<HTMLElement>("[data-live-badge]")
  const latestEl = root.querySelector<HTMLElement>("[data-latest]")
  const scope = root.dataset.scope || "live"
  const previousRanks = new Map<string, number>()

  const escapeHtml = (value: string) =>
    value.replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[char] as string))

  const markLive = (connected: boolean) => {
    if (!badge) return
    badge.classList.toggle("on", connected)
    badge.textContent = connected ? "LIVE" : "POLLING"
  }

  const render = (entries: Entry[], latest?: Entry | null) => {
    if (!tbody) return

    tbody.innerHTML = entries
      .map((entry) => {
        const prior = previousRanks.get(entry.player)
        const movement = prior == null ? "fresh" : entry.rank < prior ? "up" : entry.rank > prior ? "down" : ""
        const arrow = movement === "up" ? " ▲" : movement === "down" ? " ▼" : movement === "fresh" ? " NEW" : ""
        return `<tr class="${movement}" data-player="${escapeHtml(entry.player)}" data-points="${entry.score}" data-rank="${entry.rank}">
          <td>${entry.rank}${arrow}</td>
          <td><strong>${escapeHtml(entry.player)}</strong>${entry.company ? `<small>${escapeHtml(entry.company)}</small>` : ""}</td>
          <td>${Number(entry.score).toLocaleString()}</td>
        </tr>`
      })
      .join("")

    previousRanks.clear()
    entries.forEach((entry) => previousRanks.set(entry.player, entry.rank))

    if (empty) empty.hidden = entries.length > 0
    if (stamp) stamp.textContent = `Updated ${new Date().toLocaleTimeString()}`
    if (latestEl) {
      if (latest) {
        latestEl.hidden = false
        latestEl.innerHTML = `Latest: <strong>${escapeHtml(latest.player)}</strong> · ${Number(latest.score).toLocaleString()}`
      } else {
        latestEl.hidden = true
      }
    }
  }

  const refresh = async () => {
    const response = await fetch(`/api/v1/leaderboard?scope=${encodeURIComponent(scope)}`, {
      headers: { Accept: "application/json" }
    })
    if (!response.ok || !tbody) return
    const data = await response.json()
    render(data.entries || [], data.latest)
  }

  const highlight = (payload: { high_score?: boolean }) => {
    if (payload.high_score && banner) {
      banner.hidden = false
      window.setTimeout(() => {
        banner.hidden = true
      }, 4000)
    }
    refresh().catch(() => undefined)
  }

  Array.from(tbody?.querySelectorAll("tr") || []).forEach((row) => {
    const player = (row as HTMLElement).dataset.player
    const rank = Number((row as HTMLElement).dataset.rank)
    if (player && rank) previousRanks.set(player, rank)
  })

  window.setInterval(() => {
    refresh().catch(() => undefined)
  }, 3000)

  markLive(false)
  refresh().catch(() => undefined)

  try {
    const subscription = createConsumer().subscriptions.create(
      { channel: "LeaderboardChannel", scope },
      {
        connected() {
          markLive(true)
        },
        disconnected() {
          markLive(false)
        },
        received: highlight
      }
    )
    void subscription
  } catch {
    markLive(false)
  }
}
