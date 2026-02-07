import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overflow", "toggleButton"]

  toggle() {
    const isHidden = this.overflowTarget.classList.contains("hidden")
    if (isHidden) {
      this.overflowTarget.classList.remove("hidden")
      this.toggleButtonTarget.textContent = "show less"
    } else {
      this.overflowTarget.classList.add("hidden")
      const count = this.overflowTarget.querySelectorAll("li").length
      this.toggleButtonTarget.textContent = `see ${count} more...`
    }
  }
}
