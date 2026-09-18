import { createGame } from "../game/main"

const root = document.getElementById("rails-runner")
if (root) {
  const bootstrap = JSON.parse(root.dataset.bootstrap || "{}")
  const mount = document.getElementById("game-root")
  if (mount) createGame(mount, bootstrap)

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
}
