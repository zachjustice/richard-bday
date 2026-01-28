import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["minutes", "seconds", "hiddenField"]

  connect() {
    const totalSeconds = parseInt(this.hiddenFieldTarget.value) || 0
    this.minutesTarget.value = Math.floor(totalSeconds / 60)
    this.secondsTarget.value = totalSeconds % 60
  }

  updateTotal() {
    const minutes = parseInt(this.minutesTarget.value) || 0
    const seconds = parseInt(this.secondsTarget.value) || 0
    this.hiddenFieldTarget.value = (minutes * 60) + seconds
  }
}
