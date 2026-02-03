import { Controller } from "@hotwired/stimulus"
import { FocusTrap } from "./concerns/focus_trap"

export default class extends Controller {
  static targets = ["modal", "submitButton"]

  connect() {
    this.boundHandleEscape = this.handleEscape.bind(this)
    Object.assign(this, FocusTrap)
    this.setupFocusTrap(this.modalTarget)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleEscape)
    this.deactivateFocusTrap()
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
    this.modalTarget.setAttribute("aria-hidden", "false")
    document.addEventListener("keydown", this.boundHandleEscape)

    // Dispatch event for other controllers to sync state
    this.dispatch("opened")

    this.activateFocusTrap()
  }

  close() {
    this.modalTarget.classList.add("hidden")
    this.modalTarget.setAttribute("aria-hidden", "true")
    document.removeEventListener("keydown", this.boundHandleEscape)
    this.deactivateFocusTrap()
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