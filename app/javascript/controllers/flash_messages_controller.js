// app/javascript/controllers/flash_messages_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]
  static values = {
    autoDismiss: { type: Number, default: 15000000 }
  }

  connect() {
    this.timers = []
    this.scheduleAutoDismiss()
  }

  disconnect() {
    this.clearTimers()
  }

  scheduleAutoDismiss() {
    this.messageTargets.forEach((message) => {
      const timer = setTimeout(() => {
        this.dismissElement(message)
      }, this.autoDismissValue)

      this.timers.push(timer)
    })
  }

  dismiss(event) {
    const message = event.currentTarget.closest('[data-flash-messages-target="message"]')
    this.dismissElement(message)
  }

  dismissElement(element) {
    if (!element) return

    // Add fade-out animation
    element.style.opacity = '0'
    element.style.transform = 'translateY(-10px)'

    // Remove after animation completes
    setTimeout(() => {
      element.remove()

      // If no messages left, remove container
      if (this.messageTargets.length === 0) {
        this.element.remove()
      }
    }, 300)
  }

  clearTimers() {
    this.timers.forEach(timer => clearTimeout(timer))
    this.timers = []
  }
}