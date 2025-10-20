import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  copy(event) {
    const button = event.currentTarget
    const code = button.dataset.roomCode

    navigator.clipboard.writeText(code).then(() => {
      // Show feedback
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
}
