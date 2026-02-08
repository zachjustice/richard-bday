import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  copy(event) {
    const button = event.currentTarget
    const code = button.dataset.roomCode

    this.copyToClipboard(code).then(() => {
      const originalText = button.textContent
      button.textContent = "✓"
      button.style.background = "rgba(255, 255, 255, 0.5)"

      setTimeout(() => {
        button.textContent = originalText
        button.style.background = ""
      }, 1500)
    }).catch(err => {
      console.error("Failed to copy:", err)
    })
  }

  // Clipboard API is blocked inside iframes (e.g. Discord activity) due to
  // permissions policy. Fall back to execCommand for those environments.
  async copyToClipboard(text) {
    if (navigator.clipboard?.writeText) {
      try {
        return await navigator.clipboard.writeText(text)
      } catch { /* fall through */ }
    }

    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.style.position = "fixed"
    textarea.style.opacity = "0"
    document.body.appendChild(textarea)
    textarea.select()
    document.execCommand("copy")
    document.body.removeChild(textarea)
  }
}
