import { Controller } from "@hotwired/stimulus"
import { FocusTrap } from "concerns/focus_trap"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    this.boundHandleEscape = this.handleEscape.bind(this)
    this.initialFormHTML = document.getElementById("new_prompt_form")?.innerHTML
    Object.assign(this, FocusTrap)
    this.setupFocusTrap(this.modalTarget)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleEscape)
    this.deactivateFocusTrap()
  }

  open(event) {
    if (event) event.preventDefault()
    this.modalTarget.classList.remove("hidden")
    this.modalTarget.setAttribute("aria-hidden", "false")
    document.addEventListener("keydown", this.boundHandleEscape)
    this.activateFocusTrap()
  }

  close(event) {
    if (event) event.preventDefault()
    this.modalTarget.classList.add("hidden")
    this.modalTarget.setAttribute("aria-hidden", "true")
    document.removeEventListener("keydown", this.boundHandleEscape)
    this.deactivateFocusTrap()
    this.resetForm()
  }

  resetForm() {
    const container = document.getElementById("new_prompt_form")
    if (container && this.initialFormHTML) {
      container.innerHTML = this.initialFormHTML
    }
  }

  closeOnSuccess(event) {
    if (event.detail.success) {
      this.close()
    }
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
