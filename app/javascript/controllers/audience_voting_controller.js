import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["remaining", "starCount", "starInput", "submitBtn", "form", "answerCard"]
  static values = { maxStars: { type: Number, default: 5 } }
  static TRUNCATE_LENGTH = 30

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
    this.submitBtnTarget.setAttribute("aria-disabled", total === 0 ? "true" : "false")

    this.starCountTargets.forEach(el => {
      const answerId = el.dataset.answerId
      el.textContent = this.stars[answerId] || 0
    })

    this.starInputTargets.forEach(input => {
      const answerId = input.dataset.answerId
      input.value = this.stars[answerId] || 0
    })

    this._updateButtonStates(
      '[data-action*="increment"]',
      () => atMax,
      "Add star to"
    )
    this._updateButtonStates(
      '[data-action*="decrement"]',
      (answerId) => (this.stars[answerId] || 0) === 0,
      "Remove star from"
    )
  }

  _updateButtonStates(selector, isDisabledFn, labelPrefix) {
    const maxLen = this.constructor.TRUNCATE_LENGTH

    this.element.querySelectorAll(selector).forEach(btn => {
      const answerId = btn.dataset.answerId
      const disabled = isDisabledFn(answerId)
      btn.disabled = disabled
      btn.setAttribute("aria-disabled", disabled ? "true" : "false")
      btn.classList.toggle("opacity-40", disabled)

      const count = this.stars[answerId] || 0
      const answerCard = this.answerCardTargets.find(c => c.dataset.answerId === answerId)
      const answerText = answerCard?.querySelector("p")?.textContent?.trim() || "answer"
      const truncated = answerText.length > maxLen ? answerText.substring(0, maxLen - 3) + "..." : answerText
      btn.setAttribute("aria-label", `${labelPrefix} ${truncated} (${count} stars)`)
    })
  }
}
