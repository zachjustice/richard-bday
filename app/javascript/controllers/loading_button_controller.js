import { Controller } from "@hotwired/stimulus"

// Handles loading state for submit buttons during Turbo form submissions.
// Re-enables on turbo:submit-end so the button recovers after validation errors.
export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.form = this.element.closest("form") || this.element
    this.boundHandleSubmitStart = this.handleSubmitStart.bind(this)
    this.boundHandleSubmitEnd = this.handleSubmitEnd.bind(this)

    document.addEventListener("turbo:submit-start", this.boundHandleSubmitStart)
    document.addEventListener("turbo:submit-end", this.boundHandleSubmitEnd)
  }

  disconnect() {
    document.removeEventListener("turbo:submit-start", this.boundHandleSubmitStart)
    document.removeEventListener("turbo:submit-end", this.boundHandleSubmitEnd)
  }

  handleSubmitStart(event) {
    if (event.target === this.form) {
      this.showLoading()
    }
  }

  handleSubmitEnd(event) {
    if (event.target === this.form) {
      this.resetLoading()
    }
  }

  showLoading() {
    const button = this.hasButtonTarget ? this.buttonTarget : this.element
    button.disabled = true
    button.classList.add("btn-loading")

    if (!button.querySelector(".btn-spinner")) {
      const spinner = document.createElement("span")
      spinner.className = "btn-spinner"
      spinner.innerHTML = this.spinnerSVG()
      button.insertBefore(spinner, button.firstChild)
    }
  }

  resetLoading() {
    const button = this.hasButtonTarget ? this.buttonTarget : this.element
    button.disabled = false
    button.classList.remove("btn-loading")
    const spinner = button.querySelector(".btn-spinner")
    if (spinner) spinner.remove()
  }

  spinnerSVG() {
    return `<svg class="btn-spinner-svg" viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="10"
              stroke="currentColor"
              stroke-width="3"
              stroke-linecap="round"
              stroke-dasharray="45 20"
              fill="none"/>
    </svg>`
  }
}
