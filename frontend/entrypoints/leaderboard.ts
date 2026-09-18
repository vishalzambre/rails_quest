import { createConsumer } from "@rails/actioncable"

const root = document.querySelector<HTMLElement>("[data-leaderboard]")
if (root) {
  const banner = root.querySelector<HTMLElement>("[data-high-banner]")
  const tbody = root.querySelector<HTMLElement>("[data-rows]")
  const scope = root.dataset.scope || "conference"

  const refresh = async () => {
    const response = await fetch(`/api/v1/leaderboard?scope=${encodeURIComponent(scope)}`, {
      headers: { Accept: "application/json" }
    })
    if (!response.ok || !tbody) return
    const data = await response.json()
    const previous = Array.from(tbody.querySelectorAll("tr")).map((row) => row.querySelector("strong")?.textContent)
    tbody.innerHTML = data.entries
      .map(
        (entry: { rank: number; player: string; company?: string; score: number }, index: number) => {
          const fresh = previous.length > 0 && !previous.includes(entry.player) && index === 0
          return `<tr class="${fresh ? "fresh" : ""}" data-points="${entry.score}">
            <td>${entry.rank}</td>
            <td><strong>${escapeHtml(entry.player)}</strong>${entry.company ? `<small>${escapeHtml(entry.company)}</small>` : ""}</td>
            <td>${Number(entry.score).toLocaleString()}</td>
          </tr>`
        }
      )
      .join("")
  }

  const escapeHtml = (value: string) =>
    value.replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[char] as string))

  const highlight = (payload: { high_score?: boolean }) => {
    if (payload.high_score && banner) {
      banner.hidden = false
      window.setTimeout(() => {
        banner.hidden = true
      }, 4000)
    }
    refresh().catch(() => undefined)
  }

  window.setInterval(() => {
    refresh().catch(() => undefined)
  }, 5000)

  try {
    createConsumer().subscriptions.create({ channel: "LeaderboardChannel", scope }, {
      received: highlight
    })
  } catch {
    // Polling remains the fallback when Action Cable is unavailable.
  }
}
