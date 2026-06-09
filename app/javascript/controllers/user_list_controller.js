import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundOnAnimationEnd = this.onAnimationEnd.bind(this)
    this.element.addEventListener("animationend", this.boundOnAnimationEnd)
  }

  disconnect() {
    this.element.removeEventListener("animationend", this.boundOnAnimationEnd)
  }

  onAnimationEnd(event) {
    if (event.animationName !== "move-to-end-delay") return
    const el = event.target
    el.classList.remove("will-move-to-end", "animate-slide-in")
    this.element.appendChild(el)
    requestAnimationFrame(() => el.classList.add("animate-slide-in"))
  }
}
