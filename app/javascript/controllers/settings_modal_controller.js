import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "submitButton"]

  connect() {
    this.boundHandleEscape = this.handleEscape.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleEscape)
  }

  toggle(event) {
    event.preventDefault()
    if (this.modalTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.modalTarget.classList.remove("hidden")
    document.addEventListener("keydown", this.boundHandleEscape)

    // Dispatch event for other controllers to sync state
    this.dispatch("opened")

    // Focus the first input field
    const firstInput = this.modalTarget.querySelector("input[type='number']")
    if (firstInput) {
      setTimeout(() => firstInput.focus(), 100)
    }
  }

  close() {
    this.modalTarget.classList.add("hidden")
    document.removeEventListener("keydown", this.boundHandleEscape)
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  submitting(event) {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.classList.add("submitting")
      this.submitButtonTarget.textContent = "Saving..."
    }
  }

  submitted(event) {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.classList.remove("submitting")
      this.submitButtonTarget.textContent = "Save Settings"
    }
  }
}