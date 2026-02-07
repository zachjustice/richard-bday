import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "drawer", "button"]

  toggle() {
    this.overlayTarget.classList.toggle("hidden")
    this.drawerTarget.classList.toggle("translate-x-full")
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.drawerTarget.classList.add("translate-x-full")
  }
}
