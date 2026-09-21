import { createGame } from "../game/main"

type FullscreenDocument = Document & {
  webkitFullscreenEnabled?: boolean
  webkitFullscreenElement?: Element | null
  webkitExitFullscreen?: () => Promise<void>
}

type FullscreenHost = HTMLElement & {
  webkitRequestFullscreen?: () => Promise<void>
}

const root = document.getElementById("rails-runner")
if (root) {
  const bootstrap = JSON.parse(root.dataset.bootstrap || "{}")
  const mount = document.getElementById("game-root")
  const game = mount ? createGame(mount, bootstrap) : null

  document.querySelectorAll("[data-control]").forEach((button) => {
    const emit = (down: boolean) => {
      window.dispatchEvent(
        new CustomEvent("runner-control", {
          detail: { key: (button as HTMLElement).dataset.control, down }
        })
      )
    }
    const press = (event: Event) => {
      event.preventDefault()
      emit(true)
    }
    const release = (event: Event) => {
      event.preventDefault()
      emit(false)
    }
    button.addEventListener("pointerdown", press)
    button.addEventListener("pointerup", release)
    button.addEventListener("pointerleave", release)
    button.addEventListener("pointercancel", release)
  })

  const mute = document.querySelector("[data-mute]")
  mute?.addEventListener("click", () => {
    window.dispatchEvent(new Event("runner-mute"))
    mute.textContent = mute.textContent === "MUTE" ? "SOUND" : "MUTE"
  })

  if (game) bindFullscreen(root, game)
}

/**
 * Wires the FULL control so a landscape phone can hide browser chrome.
 * Uses the Fullscreen API when the browser allows it, then asks Phaser to
 * refit the canvas so LEFT/RIGHT/JUMP stay on the live viewport.
 */
function bindFullscreen(host: HTMLElement, game: ReturnType<typeof createGame>) {
  const button = document.querySelector<HTMLButtonElement>("[data-fullscreen]")
  const doc = document as FullscreenDocument
  if (!button) return

  const supported = !!(document.fullscreenEnabled || doc.webkitFullscreenEnabled)
  if (!supported) {
    button.hidden = true
    return
  }

  const activeElement = () => document.fullscreenElement || doc.webkitFullscreenElement || null
  const isActive = () => activeElement() === host

  const sync = () => {
    const on = isActive()
    button.textContent = on ? "EXIT" : "FULL"
    button.setAttribute("aria-pressed", on ? "true" : "false")
    game.scale.refresh()
  }

  const enter = async () => {
    const el = host as FullscreenHost
    if (el.requestFullscreen) {
      await el.requestFullscreen({ navigationUI: "hide" })
    } else {
      await el.webkitRequestFullscreen?.()
    }
    try {
      await screen.orientation?.lock?.("landscape")
    } catch {
      // iOS and desktop browsers often reject orientation lock.
    }
  }

  const exit = async () => {
    if (document.exitFullscreen) await document.exitFullscreen()
    else await doc.webkitExitFullscreen?.()
    screen.orientation?.unlock?.()
  }

  button.addEventListener("click", async () => {
    try {
      if (isActive()) await exit()
      else await enter()
    } catch {
      // User denied fullscreen or the browser blocked the gesture.
    } finally {
      sync()
    }
  })

  document.addEventListener("fullscreenchange", sync)
  document.addEventListener("webkitfullscreenchange", sync)
  window.addEventListener("resize", sync)
  window.addEventListener("orientationchange", sync)
  window.visualViewport?.addEventListener("resize", sync)
  sync()
}
