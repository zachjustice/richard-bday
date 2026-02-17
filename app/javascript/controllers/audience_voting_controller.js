import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["remaining", "kudosCount", "kudosInput", "submitBtn", "form", "answerCard"]
  static values = { maxKudos: { type: Number, default: 5 } }
  static TRUNCATE_LENGTH = 30

  connect() {
    this.kudos = {}
    this.kudosInputTargets.forEach(input => {
      this.kudos[input.dataset.answerId] = 0
    })
    this.submitted = false
    this.updateUI()
  }

  increment(event) {
    const answerId = event.currentTarget.dataset.answerId
    if (this.totalKudos() >= this.maxKudosValue) return

    this.kudos[answerId] = (this.kudos[answerId] || 0) + 1
    this.updateUI()
  }

  decrement(event) {
    const answerId = event.currentTarget.dataset.answerId
    if ((this.kudos[answerId] || 0) <= 0) return

    this.kudos[answerId] -= 1
    this.updateUI()
  }

  submit(event) {
    if (this.submitted || this.totalKudos() === 0) {
      event.preventDefault()
      return
    }
    this.submitted = true
    this.submitBtnTarget.disabled = true
    this.submitBtnTarget.classList.add("btn-loading")
  }

  totalKudos() {
    return Object.values(this.kudos).reduce((sum, n) => sum + n, 0)
  }

  updateUI() {
    const total = this.totalKudos()
    const remaining = this.maxKudosValue - total
    const atMax = remaining === 0

    this.remainingTarget.textContent = `${remaining} kudos left`
    this.submitBtnTarget.disabled = total === 0
    this.submitBtnTarget.setAttribute("aria-disabled", total === 0 ? "true" : "false")

    this.kudosCountTargets.forEach(el => {
      const answerId = el.dataset.answerId
      el.textContent = this.kudos[answerId] || 0
    })

    this.kudosInputTargets.forEach(input => {
      const answerId = input.dataset.answerId
      input.value = this.kudos[answerId] || 0
    })

    this._updateButtonStates(
      '[data-action*="increment"]',
      () => atMax,
      "Add kudos to"
    )
    this._updateButtonStates(
      '[data-action*="decrement"]',
      (answerId) => (this.kudos[answerId] || 0) === 0,
      "Remove kudos from"
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

      const count = this.kudos[answerId] || 0
      const answerCard = this.answerCardTargets.find(c => c.dataset.answerId === answerId)
      const answerText = answerCard?.querySelector("p")?.textContent?.trim() || "answer"
      const truncated = answerText.length > maxLen ? answerText.substring(0, maxLen - 3) + "..." : answerText
      btn.setAttribute("aria-label", `${labelPrefix} ${truncated} (${count} kudos)`)
    })
  }
}
