import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    prompts: String,
    tags: String
  }

  connect() {
    this.tooltip = null
  }

  show(event) {
    if (this.tooltip) return

    this.tooltip = document.createElement("div")
    this.tooltip.className = "blank-popover"
    this.tooltip.innerHTML = `
      <div class="blank-popover-content">
        <p class="blank-popover-prompts">${this.escapeHtml(this.promptsValue)}</p>
        <p class="blank-popover-tags">Tags: ${this.escapeHtml(this.tagsValue)}</p>
      </div>
    `
    document.body.appendChild(this.tooltip)
    this.position(event)
  }

  hide() {
    if (this.tooltip) {
      this.tooltip.remove()
      this.tooltip = null
    }
  }

  position(event) {
    if (!this.tooltip) return

    const offset = 10
    let x = event.clientX + offset
    let y = event.clientY + offset

    // Keep tooltip in viewport
    const rect = this.tooltip.getBoundingClientRect()
    if (x + rect.width > window.innerWidth) {
      x = event.clientX - rect.width - offset
    }
    if (y + rect.height > window.innerHeight) {
      y = event.clientY - rect.height - offset
    }

    this.tooltip.style.left = `${x}px`
    this.tooltip.style.top = `${y}px`
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  disconnect() {
    this.hide()
  }
}
