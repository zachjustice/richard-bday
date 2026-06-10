import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["scrollable", "leftFade", "rightFade"]

  connect() {
    this.scrollEl = this.hasScrollableTarget ? this.scrollableTarget : this.element
    this.update()
    this.scrollHandler = this.update.bind(this)
    this.scrollEl.addEventListener("scroll", this.scrollHandler, { passive: true })
  }

  disconnect() {
    if (this.scrollEl) this.scrollEl.removeEventListener("scroll", this.scrollHandler)
  }

  update() {
    const { scrollTop, scrollHeight, clientHeight, scrollLeft, scrollWidth, clientWidth } = this.scrollEl
    const atTop = scrollTop <= 1
    const atBottom = scrollTop + clientHeight >= scrollHeight - 1
    const atLeft = scrollLeft <= 1
    const atRight = scrollLeft + clientWidth >= scrollWidth - 1

    this.scrollEl.toggleAttribute("data-scroll-top", atTop)
    this.scrollEl.toggleAttribute("data-scroll-bottom", atBottom)
    this.scrollEl.toggleAttribute("data-scroll-left", atLeft)
    this.scrollEl.toggleAttribute("data-scroll-right", atRight)

    if (this.hasLeftFadeTarget) this.leftFadeTarget.classList.toggle("opacity-0", atLeft)
    if (this.hasRightFadeTarget) this.rightFadeTarget.classList.toggle("opacity-0", atRight)
  }
}
