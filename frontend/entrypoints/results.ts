const copyText = async (text: string) => {
  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text)
      return
    }
  } catch {
    // Permissions or a missing user-gesture can reject Clipboard; keep going.
  }

  const field = document.createElement("textarea")
  field.value = text
  field.setAttribute("readonly", "")
  field.style.position = "fixed"
  field.style.top = "0"
  field.style.left = "0"
  field.style.width = "2em"
  field.style.height = "2em"
  field.style.padding = "0"
  field.style.border = "none"
  field.style.outline = "none"
  field.style.boxShadow = "none"
  field.style.background = "transparent"
  field.style.opacity = "0"
  document.body.appendChild(field)
  field.focus()
  field.select()
  const copied = document.execCommand("copy")
  field.remove()
  if (!copied) throw new Error("copy failed")
}

const flash = (button: HTMLButtonElement, label: string) => {
  const idle = button.dataset.idleLabel || button.textContent || "SHARE SCORE"
  button.dataset.idleLabel = idle
  button.textContent = label
  window.setTimeout(() => {
    button.textContent = idle
  }, 1800)
}

const revealFallback = (message: string) => {
  const panel = document.querySelector<HTMLElement>("[data-share-fallback]")
  if (!panel) return false

  panel.hidden = false
  panel.textContent = message
  const selection = window.getSelection()
  const range = document.createRange()
  range.selectNodeContents(panel)
  selection?.removeAllRanges()
  selection?.addRange(range)
  return true
}

const bindShare = (button: HTMLButtonElement) => {
  button.addEventListener("click", async () => {
    const title = button.dataset.title || "Rails Runner"
    const text = button.dataset.text || ""
    const url = button.dataset.url || window.location.href
    const message = [text, url].filter(Boolean).join(" ")

    try {
      if (typeof navigator.share === "function") {
        await navigator.share({ title, text, url })
        return
      }
    } catch (error) {
      if (error instanceof Error && error.name === "AbortError") return
    }

    try {
      await copyText(message)
      flash(button, "COPIED")
    } catch {
      if (revealFallback(message)) {
        flash(button, "COPY THIS")
      } else {
        flash(button, "COPY FAILED")
      }
    }
  })
}

document.querySelectorAll<HTMLButtonElement>("[data-share]").forEach(bindShare)
