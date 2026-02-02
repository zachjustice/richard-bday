import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tooltip"]
  static values = {
    gamePromptId: String,
    url: String
  }

  async connect() {
    this.tooltipFrame = null
    const id = `game-prompt-${this.gamePromptIdValue}`
    const existingElement = document.querySelector(`#${id}`)

    if (existingElement) {
      this.tooltipFrame = existingElement
    } else {
      this.tooltipFrame = document.createElement("div")
      this.tooltipFrame.id = id;
      this.tooltipFrame.className = "prompt-tooltip hidden"
      this.tooltipFrame.innerHTML = `<div class=\"tooltip-loading hidden\">Loading...</div>`
      document.body.appendChild(this.tooltipFrame)

      // Fetch content via Turbo
      try {
        const response = await fetch(this.urlValue)

        if (response.ok) {
          const html = await response.text()
          const parser = new DOMParser()
          const doc = parser.parseFromString(html, "text/html")
          const content = doc.querySelector(".tooltip-content")

          if (content) {
            this.tooltipFrame.innerHTML = ""
            this.tooltipFrame.appendChild(content)
          }
        }
      } catch (error) {
        console.error("Failed to load tooltip:", error)
      }
    }
  }

  async show(event) {
    event.preventDefault()
    // Position tooltip near cursor
    this.tooltipFrame.classList.remove("hidden")
    this.position(event)
  }

  hide() {
    if (this.tooltipFrame) {
      this.tooltipFrame.classList.add("hidden")
    }
  }

  position(event) {
    if (!this.tooltipFrame) return

    const offset = 10
    let x = event.clientX + offset
    let y = event.clientY + offset

    // Keep tooltip in viewport
    const rect = this.tooltipFrame.getBoundingClientRect()
    if (x + rect.width > window.innerWidth) {
      x = event.clientX - rect.width - offset
    }
    if (y + rect.height > window.innerHeight) {
      y = event.clientY - rect.height - offset
    }

    this.tooltipFrame.style.left = `${x}px`
    this.tooltipFrame.style.top = `${y}px`
  }

  disconnect() {
    if (this.tooltipFrame) {
      this.tooltipFrame.remove()
      this.tooltipFrame = null
    }
  }
}
