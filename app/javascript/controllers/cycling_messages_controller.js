import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]
  static values = {
    interval: { type: Number, default: 15000 }
  }

  connect() {
    this.currentIndex = 0
    this.startCycling()
  }

  disconnect() {
    this.stopCycling()
  }

  startCycling() {
    this.timer = setInterval(() => {
      this.showNext()
    }, this.intervalValue)
  }

  stopCycling() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  }

  showNext() {
    this.messageTargets[this.currentIndex].classList.remove("active")
    this.currentIndex = (this.currentIndex + 1) % this.messageTargets.length
    this.messageTargets[this.currentIndex].classList.add("active")
  }
}
