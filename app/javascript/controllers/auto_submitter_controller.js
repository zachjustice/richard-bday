import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "container"]
  static values = {
    duration: { type: Number, default: 5 },
    displayAt: { type: String, default: '' }
  }

  connect() {
    this.timeRemaining = Math.round(Math.max(this.durationValue, 0))
    this.startTime = null
    this.displayAtDate = Date.parse(this.displayAtValue)
    this.lastAnnouncedTime = null

    this.createAnnouncer()
    this.start()
  }

  createAnnouncer() {
    this.announcer = document.createElement("div")
    this.announcer.setAttribute("role", "status")
    this.announcer.setAttribute("aria-live", "polite")
    this.announcer.setAttribute("aria-atomic", "true")
    this.announcer.className = "sr-only"
    this.element.appendChild(this.announcer)
  }

  disconnect() {
    this.stop()
    this.announcer?.remove()
  }

  start() {
    if (this.animationFrame) return // Already running
    
    this.startTime = Date.now()
    this.animate()
  }

  stop() {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame)
      this.animationFrame = null
    }

    // Submit the form when countdown reaches zero
    this.submitForm()
  }

  animate() {
    const elapsed = (Date.now() - this.startTime) / 1000
    this.timeRemaining = Math.max(0, this.durationValue - elapsed)
    
    this.updateColor()
    this.updateDisplay()
    
    if (this.timeRemaining > 0) {
      this.animationFrame = requestAnimationFrame(() => this.animate())
    } else {
      this.stop()
    }
  }

  updateDisplay() {
    if (Date.now() > this.displayAtDate && this.containerTarget.classList.contains("hidden")) {
      this.containerTarget.classList.remove("hidden")
    }
    const minutes = Math.round(this.timeRemaining / 60)
    const timeRemainingSeconds = Math.round(this.timeRemaining % 60) + (minutes * 60)
    this.displayTarget.textContent = `in ${timeRemainingSeconds.toString().padStart(1, '0')}`

    // Announce at key intervals for screen reader users
    const seconds = Math.round(this.timeRemaining)
    if ([10, 5, 3, 2, 1].includes(seconds) && this.lastAnnouncedTime !== seconds) {
      this.lastAnnouncedTime = seconds
      this.announce(`Auto-submit in ${seconds} second${seconds !== 1 ? "s" : ""}`)
    }
  }

  announce(message) {
    if (this.announcer) {
      this.announcer.textContent = ""
      setTimeout(() => {
        this.announcer.textContent = message
      }, 50)
    }
  }

  updateColor() {
    const progress = this.timeRemaining / this.durationValue
    
    if (progress > 0.5) {
      // Green phase (100% - 50%)
      this.element.setAttribute('data-phase', 'green')
    } else if (progress > 0.25) {
      // Orange phase (50% - 25%)
      this.element.setAttribute('data-phase', 'orange')
    } else {
      // Red phase (25% - 0%)
      this.element.setAttribute('data-phase', 'red')
    }
  }

  submitForm() {
    // Find the answer form - it's a sibling of the auto-submitter element
    const form = this.element.closest('.answer-form-section')?.querySelector('.answer-form')

    if (form) {
      // Check if there's text in the answer field before submitting
      const textArea = form.querySelector('textarea[name="text"]')

      // Only submit if there's some text (even whitespace counts as something)
      if (textArea && textArea.value.trim().length > 0) {
        form.requestSubmit()
      }
    }
  }
}