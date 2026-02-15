import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["remaining", "starCount", "starInput", "submitBtn", "form", "answerCard"]
  static values = { maxStars: { type: Number, default: 5 } }

  connect() {
    this.stars = {}
    this.starInputTargets.forEach(input => {
      this.stars[input.dataset.answerId] = 0
    })
    this.submitted = false
    this.updateUI()
  }

  increment(event) {
    const answerId = event.currentTarget.dataset.answerId
    if (this.totalStars() >= this.maxStarsValue) return

    this.stars[answerId] = (this.stars[answerId] || 0) + 1
    this.updateUI()
  }

  decrement(event) {
    const answerId = event.currentTarget.dataset.answerId
    if ((this.stars[answerId] || 0) <= 0) return

    this.stars[answerId] -= 1
    this.updateUI()
  }

  submit(event) {
    if (this.submitted || this.totalStars() === 0) {
      event.preventDefault()
      return
    }
    this.submitted = true
    this.submitBtnTarget.disabled = true
    this.submitBtnTarget.classList.add("btn-loading")
  }

  totalStars() {
    return Object.values(this.stars).reduce((sum, n) => sum + n, 0)
  }

  updateUI() {
    const total = this.totalStars()
    const remaining = this.maxStarsValue - total
    const atMax = remaining === 0

    this.remainingTarget.textContent = `${remaining} stars left`
    this.submitBtnTarget.disabled = total === 0

    this.starCountTargets.forEach(el => {
      const answerId = el.dataset.answerId
      el.textContent = this.stars[answerId] || 0
    })

    this.starInputTargets.forEach(input => {
      const answerId = input.dataset.answerId
      input.value = this.stars[answerId] || 0
    })

    // Update increment buttons
    this.element.querySelectorAll('[data-action*="increment"]').forEach(btn => {
      btn.disabled = atMax
      btn.classList.toggle("opacity-40", atMax)

      const answerId = btn.dataset.answerId
      const count = this.stars[answerId] || 0
      const answerCard = this.answerCardTargets.find(c => c.dataset.answerId === answerId)
      const answerText = answerCard?.querySelector("p")?.textContent?.trim() || "answer"
      const truncated = answerText.length > 30 ? answerText.substring(0, 27) + "..." : answerText
      btn.setAttribute("aria-label", `Add star to ${truncated} (${count} stars)`)
    })

    // Update decrement buttons
    this.element.querySelectorAll('[data-action*="decrement"]').forEach(btn => {
      const answerId = btn.dataset.answerId
      const atZero = (this.stars[answerId] || 0) === 0
      btn.disabled = atZero
      btn.classList.toggle("opacity-40", atZero)

      const count = this.stars[answerId] || 0
      const answerCard = this.answerCardTargets.find(c => c.dataset.answerId === answerId)
      const answerText = answerCard?.querySelector("p")?.textContent?.trim() || "answer"
      const truncated = answerText.length > 30 ? answerText.substring(0, 27) + "..." : answerText
      btn.setAttribute("aria-label", `Remove star from ${truncated} (${count} stars)`)
    })
  }
}
