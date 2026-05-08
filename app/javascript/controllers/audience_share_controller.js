import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  show() { this.element.classList.remove("hidden") }
  hide() { this.element.classList.add("hidden") }

  requestRestore() {
    window.dispatchEvent(new CustomEvent("audience-qr-restore"))
  }
}
