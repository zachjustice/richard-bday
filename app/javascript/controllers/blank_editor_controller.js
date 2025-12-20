// app/javascript/controllers/blank_editor_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "editLink"]

  openEditModal(event) {
    event.preventDefault()
    if (this.hasEditLinkTarget) {
      this.editLinkTarget.click()
    }
  }

  // Keep old methods for backwards compatibility (if inline form is still used)
  edit() {
    if (this.hasDisplayTarget) {
      this.displayTarget.style.display = "none"
    }
    if (this.hasFormTarget) {
      this.formTarget.style.display = "block"
    }
  }

  cancelEdit() {
    if (this.hasDisplayTarget) {
      this.displayTarget.style.display = "block"
    }
    if (this.hasFormTarget) {
      this.formTarget.style.display = "none"
    }
  }
}