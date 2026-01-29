import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "grid"]
  static values = { available: Array }

  shuffle() {
    const available = this.availableValue
    if (available.length === 0) return

    const randomEmoji = available[Math.floor(Math.random() * available.length)]
    const form = this.formTargets.find(f => f.dataset.avatar === randomEmoji)
    if (form) form.requestSubmit()
  }
}
