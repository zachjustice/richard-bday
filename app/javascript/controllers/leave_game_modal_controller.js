import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    this.boundHandleEscape = this.handleEscape.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundHandleEscape)
  }

  open(event) {
    if (event) {
      event.preventDefault()
    }
    this.modalTarget.classList.remove("hidden")
    document.addEventListener("keydown", this.boundHandleEscape)
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }
    this.modalTarget.classList.add("hidden")
    document.removeEventListener("keydown", this.boundHandleEscape)
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
