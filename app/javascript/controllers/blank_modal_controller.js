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
    console.log('open')
    if (event) {
      event.preventDefault()
    }
    this.modalTarget.classList.remove("hidden")
    document.addEventListener("keydown", this.boundHandleEscape)

    const firstInput = this.modalTarget.querySelector("input[type='text']")
    if (firstInput) {
      setTimeout(() => firstInput.focus(), 100)
    }
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
