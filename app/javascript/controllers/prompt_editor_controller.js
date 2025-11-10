// app/javascript/controllers/prompt_editor_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form"]

  edit() {
    this.displayTarget.style.display = "none"
    this.formTarget.style.display = "block"
  }

  cancelEdit() {
    this.displayTarget.style.display = "block"
    this.formTarget.style.display = "none"
  }
}