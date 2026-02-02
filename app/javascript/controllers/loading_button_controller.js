import { Controller } from "@hotwired/stimulus"

// Handles loading state for submit buttons during Turbo form submissions.
// Automatically detects form submission start/end via Turbo events.
export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.form = this.element.closest("form") || this.element
    this.bindTurboEvents()
  }

  disconnect() {
    this.unbindTurboEvents()
  }

  bindTurboEvents() {
    this.handleSubmitStart = this.showLoading.bind(this)
    this.handleSubmitEnd = this.hideLoading.bind(this)

    this.form.addEventListener("turbo:submit-start", this.handleSubmitStart)
    this.form.addEventListener("turbo:submit-end", this.handleSubmitEnd)
  }

  unbindTurboEvents() {
    this.form.removeEventListener("turbo:submit-start", this.handleSubmitStart)
    this.form.removeEventListener("turbo:submit-end", this.handleSubmitEnd)
  }

  showLoading() {
    const button = this.hasButtonTarget ? this.buttonTarget : this.element
    button.disabled = true
    button.classList.add("btn-loading")

    // Inject spinner before text
    if (!button.querySelector(".btn-spinner")) {
      const spinner = document.createElement("span")
      spinner.className = "btn-spinner"
      spinner.innerHTML = this.spinnerSVG()
      button.insertBefore(spinner, button.firstChild)
    }
  }

  hideLoading() {
    const button = this.hasButtonTarget ? this.buttonTarget : this.element
    button.disabled = false
    button.classList.remove("btn-loading")

    // Remove spinner
    const spinner = button.querySelector(".btn-spinner")
    if (spinner) spinner.remove()
  }

  // Hand-drawn style squiggly spinner SVG
  spinnerSVG() {
    return `<svg class="btn-spinner-svg" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M12 2C13.5 2.5 15 3.5 16.5 5C18.5 7 19.5 9.5 20 12C20.5 14.5 19.5 17 18 19C16.5 21 14 22 12 22C9.5 22 7 21 5.5 19C3.5 16.5 3 14 3.5 11.5C4 9 5.5 6.5 7.5 4.5C9 3 10.5 2.5 12 2"
            stroke="currentColor"
            stroke-width="2.5"
            stroke-linecap="round"
            stroke-dasharray="50 20"/>
    </svg>`
  }
}
