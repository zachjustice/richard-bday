import { Controller } from "@hotwired/stimulus"
import { FocusTrap } from "./concerns/focus_trap"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    this.boundHandleEscape = this.handleEscape.bind(this)
    Object.assign(this, FocusTrap)
    this.setupFocusTrap(this.modalTarget)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleEscape)
    this.deactivateFocusTrap()
  }

  open(event) {
    if (event) {
      event.preventDefault()
    }
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.setAttribute("aria-hidden", "false")
    document.addEventListener("keydown", this.boundHandleEscape)
    this.activateFocusTrap()
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
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
}
