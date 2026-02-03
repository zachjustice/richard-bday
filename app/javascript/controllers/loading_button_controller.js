import { Controller } from "@hotwired/stimulus"

// Handles loading state for submit buttons during Turbo form submissions.
// Loading state persists until page navigates (controller disconnects).
export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.form = this.element.closest("form") || this.element
    this.boundHandleSubmitStart = this.handleSubmitStart.bind(this)

    document.addEventListener("turbo:submit-start", this.boundHandleSubmitStart)
  }

  disconnect() {
    document.removeEventListener("turbo:submit-start", this.boundHandleSubmitStart)
  }

  handleSubmitStart(event) {
    console.log('handleSubmitStart')
    if (event.target === this.form) {
      this.showLoading()
    }
  }

  showLoading() {
    console.log('showLoading')
    const button = this.hasButtonTarget ? this.buttonTarget : this.element
    button.disabled = true
    button.classList.add("btn-loading")

    if (!button.querySelector(".btn-spinner")) {
      console.log('adding spinner')
      const spinner = document.createElement("span")
      spinner.className = "btn-spinner"
      spinner.innerHTML = this.spinnerSVG()
      button.insertBefore(spinner, button.firstChild)
    }
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
