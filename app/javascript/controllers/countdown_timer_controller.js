import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "circle"]
  static values = {
    duration: { type: Number, default: 60 },
    autoStart: { type: Boolean, default: true }
  }

  connect() {
    this.timeRemaining = Math.round(this.durationValue)
    this.startTime = null
    this.updateDisplay()
    this.setupCircle()
    
    if (this.autoStartValue) {
      this.start()
    }
  }

  disconnect() {
    this.stop()
  }

  start() {
    if (this.animationFrame) return // Already running
    
    this.startTime = Date.now()
    this.animate()
  }

  stop() {
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
      this.stop()
    }
  }

  setupCircle() {
    // SVG circle circumference = 2πr, where r = 45 (radius)
    this.circumference = 2 * Math.PI * 45
    this.circleTarget.style.strokeDasharray = this.circumference
    this.circleTarget.style.strokeDashoffset = 0
  }

  updateDisplay() {
    const minutes = Math.floor(this.timeRemaining / 60)
    const seconds = Math.round(this.timeRemaining % 60)
    this.displayTarget.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  updateCircle() {
    const progress = this.timeRemaining / this.durationValue
    const offset = this.circumference * (1 - progress)
    this.circleTarget.style.strokeDashoffset = offset
  }

  updateColor() {
    const progress = this.timeRemaining / this.durationValue
    
    if (this.timeRemaining <= 0) {
      // Flash red when time is up
      this.element.setAttribute('data-phase', 'zero')
    } else if (progress > 0.5) {
      // Green phase (100% - 50%)
      this.element.setAttribute('data-phase', 'green')
    } else if (progress > 0.25) {
      // Orange phase (50% - 25%)
      this.element.setAttribute('data-phase', 'orange')
    } else {
      // Red phase (25% - 0%)
      this.element.setAttribute('data-phase', 'red')
    }
  }
}