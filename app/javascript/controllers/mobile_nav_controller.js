import { Controller } from "@hotwired/stimulus"
import { FocusTrap } from "concerns/focus_trap"

export default class extends Controller {
  static targets = ["overlay", "drawer", "button"]

  connect() {
    this.boundHandleEscape = this.handleEscape.bind(this)
    Object.assign(this, FocusTrap)
    this.setupFocusTrap(this.overlayTarget)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleEscape)
    this.deactivateFocusTrap()
  }

  toggle() {
    if (this.overlayTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.overlayTarget.classList.remove("hidden")
    this.overlayTarget.setAttribute("aria-hidden", "false")
    this.drawerTarget.classList.remove("translate-x-full")
    document.addEventListener("keydown", this.boundHandleEscape)
    this.activateFocusTrap()
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.overlayTarget.setAttribute("aria-hidden", "true")
    this.drawerTarget.classList.add("translate-x-full")
    document.removeEventListener("keydown", this.boundHandleEscape)
    this.deactivateFocusTrap()
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
