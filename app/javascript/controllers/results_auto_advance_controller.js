import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "circle", "form"]
  static values = {
    duration: { type: Number, default: 15 }
  }

  connect() {
    this.timeRemaining = this.durationValue
    this.circumference = 2 * Math.PI * 45
    this.circleTarget.style.strokeDasharray = this.circumference
    this.circleTarget.style.strokeDashoffset = 0
    this.updateDisplay()
    this.startTime = Date.now()
    this.animate()
  }

  disconnect() {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame)
      this.animationFrame = null
    }
  }

  animate() {
    const elapsed = (Date.now() - this.startTime) / 1000
    this.timeRemaining = Math.max(0, this.durationValue - elapsed)

    this.updateDisplay()
    this.updateCircle()
    this.updateColor()

    if (this.timeRemaining > 0) {
      this.animationFrame = requestAnimationFrame(() => this.animate())
    } else {
      this.formTarget.requestSubmit()
    }
  }

  updateDisplay() {
    this.displayTarget.textContent = Math.ceil(this.timeRemaining)
  }

  updateCircle() {
    const progress = this.timeRemaining / this.durationValue
    const offset = this.circumference * (1 - progress)
    this.circleTarget.style.strokeDashoffset = offset
  }

  updateColor() {
    const progress = this.timeRemaining / this.durationValue
    let phase
    if (progress > 0.5) {
      phase = "green"
    } else if (progress > 0.25) {
      phase = "orange"
    } else {
      phase = "red"
    }
    this.element.querySelector("[data-phase]").setAttribute("data-phase", phase)
  }
}
