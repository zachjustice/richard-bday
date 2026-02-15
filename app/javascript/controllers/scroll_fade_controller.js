import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.update()
    this.scrollHandler = this.update.bind(this)
    this.element.addEventListener("scroll", this.scrollHandler, { passive: true })
  }

  disconnect() {
    this.element.removeEventListener("scroll", this.scrollHandler)
  }

  update() {
    const { scrollTop, scrollHeight, clientHeight } = this.element
    const atTop = scrollTop <= 1
    const atBottom = scrollTop + clientHeight >= scrollHeight - 1

    this.element.toggleAttribute("data-scroll-top", atTop)
    this.element.toggleAttribute("data-scroll-bottom", atBottom)
  }
}
